// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_question.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuizQuestionHiveAdapter extends TypeAdapter<QuizQuestionHive> {
  @override
  final typeId = 0;

  @override
  QuizQuestionHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizQuestionHive(
      id: (fields[0] as num).toInt(),
      question: fields[1] as String,
      options: (fields[2] as Map).cast<String, String>(),
      answer: fields[3] as String,
      difficulty: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, QuizQuestionHive obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.question)
      ..writeByte(2)
      ..write(obj.options)
      ..writeByte(3)
      ..write(obj.answer)
      ..writeByte(4)
      ..write(obj.difficulty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizQuestionHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
