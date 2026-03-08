// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProgressAdapter extends TypeAdapter<UserProgress> {
  @override
  final int typeId = 0;

  @override
  UserProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProgress(
      xp: fields[0] as int,
      streak: fields[1] as int,
      lastActivityDate: fields[2] as DateTime?,
      league: fields[3] as String,
      completedLessons: (fields[4] as List?)?.cast<String>(),
      completedSkills: (fields[5] as List?)?.cast<String>(),
      skillXp: (fields[6] as Map?)?.cast<String, int>(),
      earnedBadges: (fields[7] as List?)?.cast<String>(),
      weeklyXp: fields[8] as int,
      totalLessons: fields[9] as int,
      hearts: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserProgress obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.xp)
      ..writeByte(1)
      ..write(obj.streak)
      ..writeByte(2)
      ..write(obj.lastActivityDate)
      ..writeByte(3)
      ..write(obj.league)
      ..writeByte(4)
      ..write(obj.completedLessons)
      ..writeByte(5)
      ..write(obj.completedSkills)
      ..writeByte(6)
      ..write(obj.skillXp)
      ..writeByte(7)
      ..write(obj.earnedBadges)
      ..writeByte(8)
      ..write(obj.weeklyXp)
      ..writeByte(9)
      ..write(obj.totalLessons)
      ..writeByte(10)
      ..write(obj.hearts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
