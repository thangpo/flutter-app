import 'social_channel.dart';
import 'social_group.dart';
import 'social_page.dart';
import 'social_user.dart';

class SocialSearchResult {
  final List<SocialUser> users;
  final List<SocialPage> pages;
  final List<SocialGroup> groups;
  final List<SocialChannel> channels;

  const SocialSearchResult({
    this.users = const <SocialUser>[],
    this.pages = const <SocialPage>[],
    this.groups = const <SocialGroup>[],
    this.channels = const <SocialChannel>[],
  });

  const SocialSearchResult.empty()
      : users = const <SocialUser>[],
        pages = const <SocialPage>[],
        groups = const <SocialGroup>[],
        channels = const <SocialChannel>[];

  bool get isEmpty =>
      users.isEmpty && pages.isEmpty && groups.isEmpty && channels.isEmpty;

  SocialSearchResult copyWith({
    List<SocialUser>? users,
    List<SocialPage>? pages,
    List<SocialGroup>? groups,
    List<SocialChannel>? channels,
  }) {
    return SocialSearchResult(
      users: users ?? List<SocialUser>.from(this.users),
      pages: pages ?? List<SocialPage>.from(this.pages),
      groups: groups ?? List<SocialGroup>.from(this.groups),
      channels: channels ?? List<SocialChannel>.from(this.channels),
    );
  }
}
