class DiseaseInfo {
  final String id;
  final String name;
  final String scientificName;
  final String type;
  final String severity;
  final String description;
  final String treatment;
  final String prevention;

  const DiseaseInfo({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.type,
    required this.severity,
    required this.description,
    required this.treatment,
    required this.prevention,
  });
}

const Map<String, DiseaseInfo> kDiseases = {
  'northern_leaf_blight': DiseaseInfo(
    id: 'northern_leaf_blight',
    name: 'Northern Leaf Blight',
    scientificName: 'Exserohilum turcicum',
    type: 'Fungal',
    severity: 'High',
    description: 'Causes large, elongated grey-green or tan lesions on leaves. Spreads rapidly in cool, moist conditions and can cause significant yield loss.',
    treatment: 'Apply fungicide (mancozeb or propiconazole). Remove heavily infected leaves immediately. Improve air circulation between plants.',
    prevention: 'Use resistant varieties, practice crop rotation, avoid overhead irrigation, and scout fields regularly.',
  ),
  'gray_leaf_spot': DiseaseInfo(
    id: 'gray_leaf_spot',
    name: 'Gray Leaf Spot',
    scientificName: 'Cercospora zeae-maydis',
    type: 'Fungal',
    severity: 'High',
    description: 'Produces rectangular, gray to tan lesions parallel to leaf veins. Thrives in warm, humid weather and can reduce photosynthesis significantly.',
    treatment: 'Apply strobilurin fungicides early in disease progression. Remove and destroy crop debris after harvest.',
    prevention: 'Rotate with non-host crops, use tolerant hybrids, avoid minimum tillage in high-risk fields.',
  ),
  'common_rust': DiseaseInfo(
    id: 'common_rust',
    name: 'Common Rust',
    scientificName: 'Puccinia sorghi',
    type: 'Fungal',
    severity: 'Medium',
    description: 'Characterised by brick-red to brown pustules scattered on both leaf surfaces. Spreads by wind and thrives in cool, moist conditions.',
    treatment: 'Foliar fungicides (azoxystrobin) are effective if applied early. Most modern hybrids have good resistance.',
    prevention: 'Plant resistant hybrids. Scout fields regularly for early detection.',
  ),
  'healthy': DiseaseInfo(
    id: 'healthy',
    name: 'Healthy',
    scientificName: 'No pathogen detected',
    type: 'None',
    severity: 'None',
    description: 'No disease detected. The leaf appears healthy with no visible disease symptoms.',
    treatment: 'No treatment needed. Continue good agronomic practices.',
    prevention: 'Maintain soil health, proper plant spacing, balanced fertilisation, and regular field scouting.',
  ),
};

const List<String> kClassLabels = [
  'northern_leaf_blight',
  'gray_leaf_spot',
  'common_rust',
  'healthy',
];

const List<double> kMean = [0.485, 0.456, 0.406];
const List<double> kStd  = [0.229, 0.224, 0.225];
