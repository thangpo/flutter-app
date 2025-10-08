import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class WishListShimmer extends StatelessWidget {
  const WishListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 15,
      padding: const EdgeInsets.all(0),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          enabled: true,
          child: ListTile(
            leading: Container(height: 50, width: 50, color:  Theme.of(context).colorScheme.secondaryContainer),
            title: Container(height: 20, color:  Theme.of(context).colorScheme.secondaryContainer),
            subtitle: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(height: 10, width: 70, color:  Theme.of(context).colorScheme.secondaryContainer),
              Container(height: 10, width: 20, color:  Theme.of(context).colorScheme.secondaryContainer),
              Container(height: 10, width: 50, color:  Theme.of(context).colorScheme.secondaryContainer),
            ]),
            trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(height: 15, width: 15, decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.secondaryContainer)),
              const SizedBox(height: 10),
              Container(height: 10, width: 50, color:  Theme.of(context).colorScheme.secondaryContainer),
            ]),
          ),
        );
      },
    );
  }
}