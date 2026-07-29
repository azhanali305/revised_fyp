// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoutineTaskModelAdapter extends TypeAdapter<RoutineTaskModel> {
  @override
  final typeId = 3;

  @override
  RoutineTaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoutineTaskModel(
      id: fields[0] as String,
      patientId: fields[1] as String,
      title: fields[2] as String,
      category: fields[3] as String,
      hour: (fields[4] as num).toInt(),
      minute: (fields[5] as num).toInt(),
      repeatDaily: fields[6] == null ? true : fields[6] as bool,
      notifyEnabled: fields[7] == null ? true : fields[7] as bool,
      done: fields[8] == null ? false : fields[8] as bool,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RoutineTaskModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.hour)
      ..writeByte(5)
      ..write(obj.minute)
      ..writeByte(6)
      ..write(obj.repeatDaily)
      ..writeByte(7)
      ..write(obj.notifyEnabled)
      ..writeByte(8)
      ..write(obj.done)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineTaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
