// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PatientModelAdapter extends TypeAdapter<PatientModel> {
  @override
  final typeId = 0;

  @override
  PatientModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatientModel(
      patientId: fields[0] as String,
      caregiverId: fields[1] as String,
      fullName: fields[2] as String,
      dateOfBirth: fields[3] as DateTime,
      gender: fields[4] as String,
      relationshipWithCaregiver: fields[5] as String,
      preferredLanguage: fields[6] as String,
      emergencyContactName: fields[7] as String,
      emergencyContactPhone: fields[8] as String,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PatientModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.patientId)
      ..writeByte(1)
      ..write(obj.caregiverId)
      ..writeByte(2)
      ..write(obj.fullName)
      ..writeByte(3)
      ..write(obj.dateOfBirth)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.relationshipWithCaregiver)
      ..writeByte(6)
      ..write(obj.preferredLanguage)
      ..writeByte(7)
      ..write(obj.emergencyContactName)
      ..writeByte(8)
      ..write(obj.emergencyContactPhone)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
