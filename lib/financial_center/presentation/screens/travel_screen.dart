import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/widgets/travel_menu_widget.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/features/home/widgets/menu_widget.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/widgets/travel_banner_widget.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/widgets/location_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/widgets/tour_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/widgets/flights_list_widget.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/widgets/hotel_list_widget.dart';




class TravelScreen extends StatelessWidget {
  final bool isBackButtonExist;

  const TravelScreen({super.key, this.isBackButtonExist = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            elevation: 0,
            centerTitle: false,
            automaticallyImplyLeading: isBackButtonExist,
            backgroundColor: Theme.of(context).highlightColor,
            leading: isBackButtonExist
                ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
                : null,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(Images.logoWithNameImage, height: 35),
                const MenuWidget(),
              ],
            ),
          ),

          // Nội dung bên dưới SliverAppBar
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 20),
                TravelMenuWidget(),
                SizedBox(height: 30),
                TravelBannerWidget(),
                SizedBox(height: 20),
                LocationListWidget(),
                SizedBox(height: 20),
                TourListWidget(),
                SizedBox(height: 20),
                FlightListWidget(),
                SizedBox(height: 20),
                HotelListWidget(),
                SizedBox(height: 30),
                // Bạn có thể thêm phần khác sau này, ví dụ:
              ],
            ),
          ),
        ],
      ),
    );
  }
}

