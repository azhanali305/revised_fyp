// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safe_zone_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SafeZoneModelAdapter extends TypeAdapter<SafeZoneModel> {
  @override
  final typeId = 10;

  @override
  SafeZoneModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SafeZoneModel(
      id: fields[0] as String,
      patientId: fields[1] as String,
      name: fields[2] as String,
      latitude: (fields[3] as num).toDouble(),
      longitude: (fields[4] as num).toDouble(),
      radiusMeters: (fields[5] as num).toDouble(),
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SafeZoneModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.radiusMeters)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafeZoneModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
