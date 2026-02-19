// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      fullName: fields[1] as String,
      email: fields[2] as String,
      whatsappNumber: fields[3] as String,
      whatsappCountryCode: fields[4] as String,
      phoneNumber: fields[5] as String,
      countryCode: fields[6] as String,
      pincode: fields[7] as String,
      visitingCardUrl: fields[8] as String?,
      isEmailVerified: fields[9] as bool,
      isApproved: fields[10] as bool,
      isRejected: fields[11] as bool,
      rejectionMessage: fields[12] as String?,
      planId: fields[13] as String?,
      planName: fields[14] as String?,
      planExpiryDate: fields[15] as DateTime?,
      deviceToken: fields[16] as String?,
      createdAt: fields[17] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.whatsappNumber)
      ..writeByte(4)
      ..write(obj.whatsappCountryCode)
      ..writeByte(5)
      ..write(obj.phoneNumber)
      ..writeByte(6)
      ..write(obj.countryCode)
      ..writeByte(7)
      ..write(obj.pincode)
      ..writeByte(8)
      ..write(obj.visitingCardUrl)
      ..writeByte(9)
      ..write(obj.isEmailVerified)
      ..writeByte(10)
      ..write(obj.isApproved)
      ..writeByte(11)
      ..write(obj.isRejected)
      ..writeByte(12)
      ..write(obj.rejectionMessage)
      ..writeByte(13)
      ..write(obj.planId)
      ..writeByte(14)
      ..write(obj.planName)
      ..writeByte(15)
      ..write(obj.planExpiryDate)
      ..writeByte(16)
      ..write(obj.deviceToken)
      ..writeByte(17)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
