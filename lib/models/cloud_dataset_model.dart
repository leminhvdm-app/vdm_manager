class CloudDatasetItem {
  final String datasetKey;
  final String groupName;
  final String deviceTag;
  final int plotCount;
  final int poiCount;
  final String updatedAt;

  CloudDatasetItem({
    required this.datasetKey,
    required this.groupName,
    required this.deviceTag,
    required this.plotCount,
    required this.poiCount,
    required this.updatedAt,
  });

  factory CloudDatasetItem.fromMap(String key, Map<String, dynamic> map) {
    return CloudDatasetItem(
      datasetKey: key,
      groupName: map['groupName'] as String? ?? key,
      deviceTag: map['deviceTag'] as String? ?? '--',
      plotCount: (map['plotCount'] as num?)?.toInt() ??
          ((map['plots'] as List?)?.length ?? 0),
      poiCount: (map['poiCount'] as num?)?.toInt() ??
          ((map['pois'] as List?)?.length ?? 0),
      updatedAt: map['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'deviceTag': deviceTag,
      'plotCount': plotCount,
      'poiCount': poiCount,
      'updatedAt': updatedAt,
    };
  }
}
