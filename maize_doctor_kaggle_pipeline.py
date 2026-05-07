# =============================================================================
# MAIZE DOCTOR — COMPLETE TRAINING PIPELINE (KAGGLE VERSION)
# Final Year Project
#
# HOW TO USE ON KAGGLE:
#   1. Create a new Kaggle notebook (Notebook → New Notebook)
#   2. Enable GPU: Settings → Accelerator → GPU T4 x2
#   3. Enable Internet: Settings → Internet → On
#   4. Add dataset: Add Data → Search "corn or maize leaf disease" →
#      Add "Corn or Maize Leaf Disease Dataset" by smaranjitghose
#   5. Copy each cell below into a separate Kaggle code cell and run top-to-bottom
#
# NEW DATASET USED:
#   smaranjitghose/corn-or-maize-leaf-disease-dataset
#   ~3,852 images across 4 classes — more diverse than a single-source collection
#   Classes: Blight / Common_Rust / Gray_Leaf_Spot / Healthy
# =============================================================================


# ── CELL 1: Install packages ──────────────────────────────────────────────────
# Paste this into Kaggle Cell 1

!pip install pyngrok flask onnx onnxruntime onnx2tf -q


# ── CELL 2: Imports ───────────────────────────────────────────────────────────
# Paste this into Kaggle Cell 2

import os, json, time, base64, io, warnings
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from collections import Counter

import torch
import torch.nn as nn
from torch.utils.data import DataLoader, random_split, Subset
from torchvision import datasets, transforms, models
from sklearn.metrics import classification_report, confusion_matrix

warnings.filterwarnings('ignore')
print(f"PyTorch version : {torch.__version__}")
print(f"CUDA available  : {torch.cuda.is_available()}")
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Using device    : {DEVICE}")


# ── CELL 3: Configuration ─────────────────────────────────────────────────────
# Paste this into Kaggle Cell 3
# If you added a different dataset, update DATA_DIR to match its path.

# ── Paths ──
# After adding smaranjitghose/corn-or-maize-leaf-disease-dataset the path is:
DATA_DIR   = "/kaggle/input/corn-or-maize-leaf-disease-dataset"
OUTPUT_DIR = "/kaggle/working/models"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ── Class mapping ──
# The Kaggle dataset uses capitalised folder names.
# We remap them to match what the Flutter app expects (alphabetical order matters).
CLASS_MAP = {
    "Blight":         "northern_leaf_blight",
    "Common_Rust":    "common_rust",
    "Gray_Leaf_Spot": "gray_leaf_spot",
    "Healthy":        "healthy",
}
# After remapping, alphabetical order will be:
#   0=common_rust, 1=gray_leaf_spot, 2=healthy, 3=northern_leaf_blight
# This MUST match the order in lib/constants/diseases.dart in the Flutter app.

# ── Hyperparameters ──
IMG_SIZE    = 224
BATCH_SIZE  = 32
NUM_EPOCHS  = 15
LR          = 1e-4
NUM_CLASSES = 4
TEMPERATURE = 2.0   # softens over-confident predictions on real field photos
THRESHOLD   = 0.55  # server-side non-leaf rejection

print("Configuration loaded")
print(f"  DATA_DIR   : {DATA_DIR}")
print(f"  OUTPUT_DIR : {OUTPUT_DIR}")
print(f"  Device     : {DEVICE}")


# ── CELL 4: Data Loading & EDA ────────────────────────────────────────────────
# Paste this into Kaggle Cell 4

MEAN = [0.485, 0.456, 0.406]
STD  = [0.229, 0.224, 0.225]

train_tf = transforms.Compose([
    transforms.Resize((IMG_SIZE, IMG_SIZE)),
    transforms.RandomHorizontalFlip(),
    transforms.RandomVerticalFlip(p=0.2),
    transforms.RandomRotation(20),
    transforms.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.2, hue=0.05),
    transforms.RandomAffine(degrees=0, translate=(0.1, 0.1)),
    transforms.ToTensor(),
    transforms.Normalize(MEAN, STD),
])

val_tf = transforms.Compose([
    transforms.Resize((IMG_SIZE, IMG_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(MEAN, STD),
])

# ── Load with ImageFolder (uses train_tf initially; we swap for val/test below) ──
full_ds = datasets.ImageFolder(DATA_DIR, transform=train_tf)
print(f"Raw folders found: {full_ds.classes}")

# ── Remap class names ──
new_class_to_idx = {}
for orig_name, new_name in CLASS_MAP.items():
    if orig_name in full_ds.class_to_idx:
        new_class_to_idx[new_name] = full_ds.class_to_idx[orig_name]

if not new_class_to_idx:
    # Dataset already uses correct names — no remapping needed
    new_class_to_idx = full_ds.class_to_idx

# Re-index so that indices match alphabetical order (critical for Flutter)
CLASS_NAMES = sorted(new_class_to_idx.keys())
class_to_idx_sorted = {name: i for i, name in enumerate(CLASS_NAMES)}

# Update targets to use new indices
orig_to_new = {
    full_ds.class_to_idx[orig]: class_to_idx_sorted[new]
    for orig, new in CLASS_MAP.items()
    if orig in full_ds.class_to_idx
} if CLASS_MAP else {v: v for v in full_ds.class_to_idx.values()}

full_ds.samples = [(p, orig_to_new[l]) for p, l in full_ds.samples]
full_ds.targets  = [orig_to_new[l] for l in full_ds.targets]
full_ds.class_to_idx = class_to_idx_sorted
full_ds.classes = CLASS_NAMES

print(f"\nClass names (alphabetical — matches Flutter): {CLASS_NAMES}")
print(f"Total images: {len(full_ds)}")

counts = Counter(full_ds.targets)
for i, name in enumerate(CLASS_NAMES):
    print(f"  [{i}] {name:30s}: {counts[i]:5d} images")

# ── 70 / 15 / 15 split ──
n       = len(full_ds)
n_train = int(0.70 * n)
n_val   = int(0.15 * n)
n_test  = n - n_train - n_val
gen     = torch.Generator().manual_seed(42)
train_indices, val_indices, test_indices = random_split(
    range(n), [n_train, n_val, n_test], generator=gen
)

train_ds = Subset(full_ds, list(train_indices))
val_ds   = Subset(full_ds, list(val_indices))
test_ds  = Subset(full_ds, list(test_indices))

# Swap transforms for val/test subsets
import copy
val_ds_copy  = copy.deepcopy(full_ds); val_ds_copy.transform  = val_tf
test_ds_copy = copy.deepcopy(full_ds); test_ds_copy.transform = val_tf
val_ds  = Subset(val_ds_copy,  list(val_indices))
test_ds = Subset(test_ds_copy, list(test_indices))

train_loader = DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True,  num_workers=2, pin_memory=True)
val_loader   = DataLoader(val_ds,   batch_size=BATCH_SIZE, shuffle=False, num_workers=2, pin_memory=True)
test_loader  = DataLoader(test_ds,  batch_size=BATCH_SIZE, shuffle=False, num_workers=2, pin_memory=True)

print(f"\nSplits → Train: {n_train} | Val: {n_val} | Test: {n_test}")

# ── Sample grid ──
unnorm = transforms.Compose([
    transforms.Normalize([0,0,0], [1/s for s in STD]),
    transforms.Normalize([-m for m in MEAN], [1,1,1]),
])
fig, axes = plt.subplots(2, 4, figsize=(16, 8))
for i, ax in enumerate(axes.flat):
    img, label = train_ds[i * 10]
    img_show = unnorm(img).permute(1,2,0).clamp(0,1).numpy()
    ax.imshow(img_show)
    ax.set_title(CLASS_NAMES[label], fontsize=10)
    ax.axis('off')
plt.suptitle('Sample Training Images', fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/sample_images.png", dpi=100, bbox_inches='tight')
plt.show()
print("Sample grid saved.")


# ── CELL 5: Model Definitions ─────────────────────────────────────────────────
# Paste this into Kaggle Cell 5

def build_model(arch: str) -> nn.Module:
    if arch == 'resnet50':
        m = models.resnet50(weights=models.ResNet50_Weights.IMAGENET1K_V1)
        m.fc = nn.Linear(m.fc.in_features, NUM_CLASSES)
    elif arch == 'mobilenetv2':
        m = models.mobilenet_v2(weights=models.MobileNet_V2_Weights.IMAGENET1K_V1)
        m.classifier[1] = nn.Linear(m.classifier[1].in_features, NUM_CLASSES)
    elif arch == 'efficientnetb0':
        m = models.efficientnet_b0(weights=models.EfficientNet_B0_Weights.IMAGENET1K_V1)
        m.classifier[1] = nn.Linear(m.classifier[1].in_features, NUM_CLASSES)
    else:
        raise ValueError(f"Unknown arch: {arch}")
    return m.to(DEVICE)


def train_model(model, name, epochs=NUM_EPOCHS, lr=LR):
    criterion = nn.CrossEntropyLoss(label_smoothing=0.1)
    optimizer = torch.optim.AdamW(model.parameters(), lr=lr, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=epochs)

    best_val_acc = 0.0
    best_path    = f"{OUTPUT_DIR}/{name}_best.pth"
    history      = {'train_loss': [], 'val_loss': [], 'train_acc': [], 'val_acc': []}

    for epoch in range(1, epochs + 1):
        # Train
        model.train()
        t_loss, t_correct = 0.0, 0
        for imgs, labels in train_loader:
            imgs, labels = imgs.to(DEVICE), labels.to(DEVICE)
            optimizer.zero_grad()
            loss = criterion(model(imgs), labels)
            loss.backward()
            optimizer.step()
            with torch.no_grad():
                out = model(imgs)
            t_loss    += loss.item() * imgs.size(0)
            t_correct += (out.argmax(1) == labels).sum().item()

        # Val
        model.eval()
        v_loss, v_correct = 0.0, 0
        with torch.no_grad():
            for imgs, labels in val_loader:
                imgs, labels = imgs.to(DEVICE), labels.to(DEVICE)
                out   = model(imgs)
                loss  = criterion(out, labels)
                v_loss    += loss.item() * imgs.size(0)
                v_correct += (out.argmax(1) == labels).sum().item()

        t_acc = t_correct / n_train
        v_acc = v_correct / n_val
        t_loss /= n_train
        v_loss /= n_val

        history['train_loss'].append(t_loss)
        history['val_loss'].append(v_loss)
        history['train_acc'].append(t_acc)
        history['val_acc'].append(v_acc)

        flag = ''
        if v_acc > best_val_acc:
            best_val_acc = v_acc
            torch.save(model.state_dict(), best_path)
            flag = ' ← best saved'

        print(f"[{name}] Ep {epoch:02d}/{epochs}  "
              f"train={t_acc:.4f}({t_loss:.4f})  "
              f"val={v_acc:.4f}({v_loss:.4f}){flag}")
        scheduler.step()

    model.load_state_dict(torch.load(best_path, map_location=DEVICE))
    print(f"Best val acc for {name}: {best_val_acc:.4f} ({best_val_acc*100:.2f}%)")
    return model, history, best_val_acc


print("Model builder and trainer defined.")


# ── CELL 6: Train ResNet50 ────────────────────────────────────────────────────
# Paste this into Kaggle Cell 6 (runs ~8-12 min on GPU T4)

print("=" * 60)
print("TRAINING ResNet50 (server / API model)")
print("=" * 60)
resnet, resnet_hist, resnet_best = train_model(build_model('resnet50'), 'resnet50')


# ── CELL 7: Train MobileNetV2 ─────────────────────────────────────────────────
# Paste this into Kaggle Cell 7 (this becomes the TFLite on-device model)

print("=" * 60)
print("TRAINING MobileNetV2 (on-device TFLite model)")
print("=" * 60)
mobilenet, mn_hist, mn_best = train_model(build_model('mobilenetv2'), 'mobilenetv2')


# ── CELL 8: Train EfficientNetB0 ──────────────────────────────────────────────
# Paste this into Kaggle Cell 8

print("=" * 60)
print("TRAINING EfficientNetB0 (benchmark)")
print("=" * 60)
efficientnet, en_hist, en_best = train_model(build_model('efficientnetb0'), 'efficientnetb0')

# Summary
print("\n" + "=" * 60)
print("TRAINING SUMMARY")
print("=" * 60)
for name, acc in [('ResNet50', resnet_best), ('MobileNetV2', mn_best), ('EfficientNetB0', en_best)]:
    print(f"  {name:20s}: {acc*100:.2f}%")


# ── CELL 9: Training Curves ───────────────────────────────────────────────────
# Paste this into Kaggle Cell 9

fig, axes = plt.subplots(2, 3, figsize=(18, 10))
configs = [
    ('ResNet50',      resnet_hist,  axes[0, 0], axes[1, 0]),
    ('MobileNetV2',   mn_hist,      axes[0, 1], axes[1, 1]),
    ('EfficientNetB0', en_hist,     axes[0, 2], axes[1, 2]),
]
for name, hist, ax_acc, ax_loss in configs:
    ax_acc.plot(hist['train_acc'], label='Train', color='steelblue')
    ax_acc.plot(hist['val_acc'],   label='Val',   color='tomato')
    ax_acc.set_title(f'{name} — Accuracy'); ax_acc.set_ylabel('Accuracy')
    ax_acc.legend(); ax_acc.grid(alpha=0.3)

    ax_loss.plot(hist['train_loss'], label='Train', color='steelblue')
    ax_loss.plot(hist['val_loss'],   label='Val',   color='tomato')
    ax_loss.set_title(f'{name} — Loss'); ax_loss.set_ylabel('Loss')
    ax_loss.set_xlabel('Epoch'); ax_loss.legend(); ax_loss.grid(alpha=0.3)

plt.suptitle('Training Curves — All Models', fontsize=14, fontweight='bold')
plt.tight_layout()
plt.savefig(f"{OUTPUT_DIR}/training_curves.png", dpi=120, bbox_inches='tight')
plt.show()
print("Training curves saved.")


# ── CELL 10: Evaluation on Test Set ──────────────────────────────────────────
# Paste this into Kaggle Cell 10

def evaluate_model(model, loader, model_name):
    model.eval()
    all_preds, all_labels = [], []
    with torch.no_grad():
        for imgs, labels in loader:
            imgs = imgs.to(DEVICE)
            logits = model(imgs) / TEMPERATURE
            probs  = torch.softmax(logits, dim=1)
            preds  = probs.argmax(1)
            all_preds.extend(preds.cpu().numpy())
            all_labels.extend(labels.numpy())

    acc = (np.array(all_preds) == np.array(all_labels)).mean()
    print(f"\n{'='*60}")
    print(f"{model_name} — Test Accuracy: {acc*100:.2f}%")
    print(f"{'='*60}")
    print(classification_report(all_labels, all_preds, target_names=CLASS_NAMES, digits=4))

    cm = confusion_matrix(all_labels, all_preds)
    fig, ax = plt.subplots(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                xticklabels=CLASS_NAMES, yticklabels=CLASS_NAMES, ax=ax,
                linewidths=0.5)
    ax.set_xlabel('Predicted', fontsize=11)
    ax.set_ylabel('Actual', fontsize=11)
    ax.set_title(f'{model_name} — Confusion Matrix (Test Set)', fontsize=12, fontweight='bold')
    plt.xticks(rotation=30, ha='right'); plt.yticks(rotation=0)
    plt.tight_layout()
    plt.savefig(f"{OUTPUT_DIR}/{model_name.lower()}_confusion.png", dpi=120, bbox_inches='tight')
    plt.show()
    return acc

resnet_test    = evaluate_model(resnet,       test_loader, 'ResNet50')
mobilenet_test = evaluate_model(mobilenet,    test_loader, 'MobileNetV2')
effnet_test    = evaluate_model(efficientnet, test_loader, 'EfficientNetB0')

print("\nFINAL TEST ACCURACIES (with temperature scaling T=2.0):")
for name, acc in [('ResNet50', resnet_test), ('MobileNetV2', mobilenet_test), ('EfficientNetB0', effnet_test)]:
    print(f"  {name:20s}: {acc*100:.2f}%")


# ── CELL 11: Save class_info.json ────────────────────────────────────────────
# Paste this into Kaggle Cell 11
# This JSON tells the Flask API and Flutter app the class order.

class_info = {
    "classes":       CLASS_NAMES,
    "class_to_idx":  {c: i for i, c in enumerate(CLASS_NAMES)},
    "temperature":   TEMPERATURE,
    "threshold":     THRESHOLD,
    "model_arch":    "resnet50",
    "img_size":      IMG_SIZE,
    "normalization": {"mean": MEAN, "std": STD},
}
with open(f"{OUTPUT_DIR}/class_info.json", 'w') as f:
    json.dump(class_info, f, indent=2)

print("class_info.json saved:")
print(json.dumps(class_info, indent=2))


# ── CELL 12: Export MobileNetV2 → TFLite (for Flutter on-device inference) ───
# Paste this into Kaggle Cell 12
# This replaces assets/models/maize_model.tflite in your Flutter project.

mobilenet.eval()
dummy   = torch.randn(1, 3, IMG_SIZE, IMG_SIZE).to(DEVICE)
onnx_path = f"{OUTPUT_DIR}/mobilenetv2.onnx"

torch.onnx.export(
    mobilenet.cpu(), dummy.cpu(), onnx_path,
    input_names=['input'], output_names=['output'],
    dynamic_axes={'input': {0: 'batch'}, 'output': {0: 'batch'}},
    opset_version=11,
    verbose=False,
)
print(f"ONNX exported: {onnx_path}")

# ONNX → TF SavedModel → TFLite
try:
    import onnx2tf
    saved_model_dir = f"{OUTPUT_DIR}/mobilenetv2_savedmodel"
    onnx2tf.convert(
        input_onnx_file_path=onnx_path,
        output_folder_path=saved_model_dir,
        non_verbose=True,
    )
    print(f"SavedModel created: {saved_model_dir}")

    import tensorflow as tf
    converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    tflite_path = f"{OUTPUT_DIR}/maize_model.tflite"
    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)

    size_kb = os.path.getsize(tflite_path) // 1024
    print(f"\nTFLite model saved: {tflite_path} ({size_kb} KB)")
    print("\n>>> NEXT STEP: Download maize_model.tflite from Kaggle output")
    print("    and copy it to Flutter:  assets/models/maize_model.tflite")

except Exception as e:
    print(f"TFLite conversion error: {e}")
    print("The .pth files are still saved and can be used with the Flask API.")
    print("For TFLite, try running the conversion in a separate Kaggle notebook.")


# ── CELL 13: Flask API serving (run this LAST, it blocks the notebook) ────────
# Paste this into Kaggle Cell 13 ONLY when you want to serve the model.
# NOTE: Keep all other cells above this one already executed before running this.
#
# Kaggle DOES support ngrok tunnels. Make sure "Internet" is ON in notebook settings.

!pip install flask pyngrok -q

import threading
from flask import Flask, request, jsonify
from PIL import Image
from pyngrok import ngrok

# ── Load saved ResNet50 ──
API_MODEL_PATH = f"{OUTPUT_DIR}/resnet50_best.pth"
api_model = build_model('resnet50')
api_model.load_state_dict(torch.load(API_MODEL_PATH, map_location=DEVICE))
api_model.eval()
print(f"API model loaded from {API_MODEL_PATH}")

preprocess = transforms.Compose([
    transforms.Resize((IMG_SIZE, IMG_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(MEAN, STD),
])

def is_valid_image(img: Image.Image) -> bool:
    arr = np.array(img).astype(np.float32) / 255.0
    return float(arr.std()) >= 0.05

def has_enough_green(img: Image.Image) -> bool:
    arr = np.array(img)
    r, g, b = arr[:,:,0], arr[:,:,1], arr[:,:,2]
    green_pixels = ((g > r) & (g > b) & (g > 40)).sum()
    return float(green_pixels) / (arr.shape[0] * arr.shape[1]) >= 0.05

app = Flask(__name__)

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json(force=True)
    if not data or 'image' not in data:
        return jsonify({'error': 'missing_image', 'message': 'No image provided'}), 400

    try:
        img_bytes = base64.b64decode(data['image'])
        img = Image.open(io.BytesIO(img_bytes)).convert('RGB')
    except Exception:
        return jsonify({'error': 'bad_image', 'message': 'Could not decode image'}), 400

    if not is_valid_image(img):
        return jsonify({'error': 'not_a_leaf', 'message': 'Image appears to be blank or uniform'}), 422

    if not has_enough_green(img):
        return jsonify({'error': 'not_a_leaf', 'message': 'Image does not appear to be a plant leaf'}), 422

    tensor = preprocess(img).unsqueeze(0).to(DEVICE)
    with torch.no_grad():
        logits = api_model(tensor) / TEMPERATURE
        probs  = torch.softmax(logits, dim=1)[0]

    confidence = float(probs.max())
    pred_idx   = int(probs.argmax())

    if confidence < THRESHOLD:
        return jsonify({'error': 'not_a_leaf', 'message': 'Image does not appear to be a maize leaf'}), 422

    alternatives = [
        {'label': CLASS_NAMES[i], 'confidence': float(probs[i])}
        for i in range(NUM_CLASSES) if i != pred_idx
    ]
    alternatives.sort(key=lambda x: x['confidence'], reverse=True)

    return jsonify({
        'disease':      CLASS_NAMES[pred_idx],
        'confidence':   confidence,
        'alternatives': alternatives,
    })

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'model': 'resnet50', 'classes': CLASS_NAMES})

# ── Start ngrok tunnel ──
# Get a free authtoken from https://dashboard.ngrok.com/get-started/your-authtoken
NGROK_TOKEN = "PASTE_YOUR_NGROK_TOKEN_HERE"
ngrok.set_auth_token(NGROK_TOKEN)
public_url = ngrok.connect(5000)
print(f"\n{'='*60}")
print(f"API is live at: {public_url}/predict")
print(f"Health check  : {public_url}/health")
print(f"{'='*60}")
print("Paste the URL above into the Maize Doctor app Settings → Backend URL")
print("(Include /predict at the end only in the actual HTTP call — the app adds it)")
print("\nPress Kernel → Interrupt to stop the server.")

# Run Flask in a background thread so Kaggle doesn't time out
def run():
    app.run(port=5000, debug=False, use_reloader=False)

t = threading.Thread(target=run, daemon=True)
t.start()
t.join()
