import 'package:json_annotation/json_annotation.dart';
import 'package:minsk8/import.dart';

part 'profile.g.dart';

@JsonSerializable()
class ProfileModel {
  final MemberModel member;
  final List<PaymentModel> payments;
  final List<ItemModel> myItems;
  final List<ItemModel> whishes;
  final List<BidModel> bids;

  ProfileModel(
    this.member,
    this.payments,
    this.myItems,
    this.whishes,
    this.bids,
  );

  get avatarUrl => 'https://example.com/avatars/?id=${member.id}';

  get balance => 0; // TODO: реализовать баланс по сумме payments

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);
}
