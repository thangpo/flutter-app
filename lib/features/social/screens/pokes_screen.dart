import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/controllers/social_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/screens/profile_screen.dart';

class PokesScreen extends StatefulWidget {
  const PokesScreen({super.key});

  @override
  State<PokesScreen> createState() => _PokesScreenState();
}

class _PokesScreenState extends State<PokesScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialController>().fetchPokes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SocialController>();
    final pokes = ctrl.pokes;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTranslated('who_poked_me', context) ?? 'Ai chọc tôi?',
        ),
      ),
      body: ctrl.loadingPokes
          ? const Center(child: CircularProgressIndicator())
          : pokes.isEmpty
              ? Center(
                  child: Text(
                    getTranslated('no_one_poked_you', context) ??
                        'Chưa ai chọc bạn 😢',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: pokes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final item = pokes[i];
                    final user = item["user_data"] ?? {};

                    return Container(
                      key: ValueKey(item["id"]),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== AVATAR =====
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.network(
                              user["avatar_full"] != null
                                  ? "${AppConstants.socialBaseUrl}/${user["avatar_full"]}"
                                  : (user["avatar"] ?? ""),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),

                          const SizedBox(width: 14),

                          // ===== INFO (NAME + USERNAME + STATUS) =====
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user["name"] ??
                                      (getTranslated('no_name', context) ??
                                          'Không tên'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "@${user["username"]}",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  getTranslated('has_poked_you', context) ??
                                      'Đã chọc bạn',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ===== ACTION BUTTONS (CHỌC LẠI + XEM) =====
                          SizedBox(
                            width: 160,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // HÀNG 1: CHỌC LẠI + XEM (cùng 1 hàng)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Nút CHỌC LẠI
                                    ElevatedButton(
                                      onPressed: () async {
                                        final userId = int.parse(
                                          user["user_id"].toString(),
                                        );

                                        final ok = await context
                                            .read<SocialController>()
                                            .createPoke(userId);

                                        if (!ok && mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                getTranslated(
                                                        'already_poked_this_user',
                                                        context) ??
                                                    'Bạn đã chọc người này rồi!',
                                              ),
                                            ),
                                          );
                                        } else if (ok && mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                getTranslated(
                                                        'poke_back_success',
                                                        context) ??
                                                    'Chọc lại thành công!',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade600,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        minimumSize: const Size(0, 32),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        getTranslated('retaliate', context) ??
                                            'Trả đũa',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Nút XEM
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProfileScreen(
                                              targetUserId: user["user_id"],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        getTranslated(
                                                'view_profile', context) ??
                                            'Xem',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
