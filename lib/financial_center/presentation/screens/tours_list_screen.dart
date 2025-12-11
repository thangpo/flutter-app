import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/financial_center/presentation/services/tour_service.dart';
import '../services/location_service.dart';

class TourListScreen extends StatefulWidget {
  final LocationModel location;
  const TourListScreen({super.key, required this.location});

  @override
  State<TourListScreen> createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen> {
  List<dynamic> tours = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final data = await TourService.fetchToursByLocation(widget.location.id);
      setState(() => tours = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.location.name),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadTours,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tours.length,
          itemBuilder: (context, index) {
            final tour = tours[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    tour['image'] ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
                  ),
                ),
                title: Text(tour['title'] ?? ''),
                subtitle: Text('${tour['price'] ?? 0}đ'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Mở chi tiết tour
                },
              ),
            );
          },
        ),
      ),
    );
  }
}