// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuizSessionAdapter extends TypeAdapter<QuizSession> {
  @override
  final typeId = 1;

  @override
  QuizSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizSession(
      sessionId: fields[0] as String,
      sourceFileName: fields[1] as String,
      createdAt: fields[2] as DateTime,
      questions: (fields[3] as List).cast<QuizQuestionHive>(),
      userAnswerKeys: (fields[4] as List).cast<String>(),
      difficulty: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, QuizSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.sourceFileName)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.questions)
      ..writeByte(4)
      ..write(obj.userAnswerKeys)
      ..writeByte(5)
      ..write(obj.difficulty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
