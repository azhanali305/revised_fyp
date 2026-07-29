// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calming_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalmingItemModelAdapter extends TypeAdapter<CalmingItemModel> {
  @override
  final typeId = 2;

  @override
  CalmingItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalmingItemModel(
      id: fields[0] as String,
      patientId: fields[1] as String,
      title: fields[2] as String,
      type: fields[3] as String,
      audioPath: fields[4] as String?,
      isAsset: fields[5] == null ? false : fields[5] as bool,
      durationMinutes: fields[6] == null ? 3 : (fields[6] as num).toInt(),
      breatheInSeconds: fields[7] == null ? 4 : (fields[7] as num).toInt(),
      holdSeconds: fields[8] == null ? 4 : (fields[8] as num).toInt(),
      breatheOutSeconds: fields[9] == null ? 4 : (fields[9] as num).toInt(),
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CalmingItemModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.audioPath)
      ..writeByte(5)
      ..write(obj.isAsset)
      ..writeByte(6)
      ..write(obj.durationMinutes)
      ..writeByte(7)
      ..write(obj.breatheInSeconds)
      ..writeByte(8)
      ..write(obj.holdSeconds)
      ..writeByte(9)
      ..write(obj.breatheOutSeconds)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalmingItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
