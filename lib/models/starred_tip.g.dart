// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'starred_tip.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StarredTipAdapter extends TypeAdapter<StarredTip> {
  @override
  final int typeId = 3;

  @override
  StarredTip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StarredTip(
      tipId: fields[0] as String,
      contentEn: fields[1] as String,
      contentSi: fields[2] as String,
      category: fields[3] as String,
      starredAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StarredTip obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.tipId)
      ..writeByte(1)
      ..write(obj.contentEn)
      ..writeByte(2)
      ..write(obj.contentSi)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.starredAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StarredTipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
