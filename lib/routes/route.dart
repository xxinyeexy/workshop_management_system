import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:workshop_management_system/modules/models/InventoryInfo.dart';
import 'package:workshop_management_system/modules/models/MarketplaceInfo.dart';

//Page of Manage Inventory Module
import '../modules/inventory/views/page/InventoryPage.dart';
import '../modules/inventory/views/page/AddInventoryForm.dart';
import '../modules/inventory/views/page/EditInventoryForm.dart';
import '../modules/inventory/views/page/Marketplace.dart';
import '../modules/inventory/views/page/MarketplaceSaleListingPage.dart';
import '../modules/inventory/views/page/MarketplaceRequestListingPage.dart';
import '../modules/inventory/views/page/SellForm.dart';
import '../modules/inventory/views/page/RequestInventoryForm.dart';
import '../modules/inventory/views/page/SaleDetailsPage.dart' as sale_details;
import '../modules/inventory/views/page/RequestDetailsPage.dart';

class AppRoutes {
  AppRoutes._();

  //Routes of Manage Inventory Module (Inventory Part)
  static const String inventory = '/inventory';
  static const String addInventory = '/addInventory';
  static const String editInventory = '/editInventory';

  //Routes of Manage Inventory Module (Marketplace Part)
  static const String marketplace = '/marketplace';
  static const String saleListing = '/saleListing';
  static const String requestListing = '/requestListing';
  static const String sellForm = '/sellForm';
  static const String requestForm = '/requestForm';
  static const String saleDetails = '/saleDetails';
  static const String saleDetailsCopy = '/saleDetailsCopy';
  static const String requestDetails = '/requestDetails';

  
}

class AppRouter {
  // Prevent instantiation
  AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Inventory Module Routes
     
      case AppRoutes.addInventory:
        return MaterialPageRoute(builder: (_) => const AddInventoryPage());

      case AppRoutes.editInventory:
        final inventory = settings.arguments as InventoryInfo;
        return MaterialPageRoute(
          builder: (_) => EditInventoryPage(item: inventory),
        );

      // Marketplace Module Routes
      case AppRoutes.marketplace:
        // Expecting arguments as a Map<String, dynamic>
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final String userRole = args['userRole'] as String? ?? '';
        final String userName = args['userName'] as String? ?? '';
        final String userPosition = args['userPosition'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => Marketplace(
            userRole: userRole,
            userName: userName,
            userPosition: userPosition,
          ),
        );
     
      case AppRoutes.saleListing:
        final GeoPoint? userGeoPoint = settings.arguments as GeoPoint?;
        return MaterialPageRoute(
          builder:
              (_) => MarketplaceSaleListingPage(user_geo_point: userGeoPoint),
        );

      case AppRoutes.requestListing:
        final GeoPoint? userGeoPoint = settings.arguments as GeoPoint?;
        return MaterialPageRoute(
          builder:
              (_) => MarketplaceRequestListingPage(user_geo_point: userGeoPoint),
        );

      case AppRoutes.sellForm:
        final GeoPoint? userGeoPoint = settings.arguments as GeoPoint?;
        return MaterialPageRoute(
          builder: (_) => SellForm(user_geo_point: userGeoPoint),
        );

      case AppRoutes.requestForm:
        final GeoPoint? userGeoPoint = settings.arguments as GeoPoint?;
        return MaterialPageRoute(
          builder: (_) => RequestInventoryForm(user_geo_point: userGeoPoint),
        );

      case AppRoutes.saleDetails:
        final Map<String, dynamic> args =
            settings.arguments as Map<String, dynamic>;
        final MarketplaceInfo saleItem = args['listing'] as MarketplaceInfo;
        final GeoPoint? userGeoPoint = args['user_geo_point'] as GeoPoint?;
        final int selectedQuantity = args['selected_quantity'] as int;
        return MaterialPageRoute(
          builder:
              (_) =>
                  sale_details.SaleDetailsPage(sale_item: saleItem, user_geo_point: userGeoPoint,
                    selected_quantity: selectedQuantity,
                  ),
        );

  


      case AppRoutes.requestDetails:
        final Map<String, dynamic> args =
            settings.arguments as Map<String, dynamic>;
        final MarketplaceInfo requestItem = args['listing'] as MarketplaceInfo;
        final GeoPoint? userGeoPoint = args['user_geo_point'] as GeoPoint?;
        return MaterialPageRoute(
          builder:
              (_) => RequestDetailsPage(
                request_item: requestItem,
                user_geo_point: userGeoPoint,
              ),
        );

      default:
        // If there is no such named route, return an error page
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                appBar: AppBar(title: const Text('Page Not Found')),
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }

  /// Navigate to a named route
  static Future<dynamic> navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  /// Navigate to a named route and remove all previous routes
  static Future<dynamic> navigateAndRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Navigate to a named route and replace the current route
  static Future<dynamic> navigateAndReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(
      context,
    ).pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Go back to previous screen
  static void goBack(BuildContext context, [dynamic result]) {
    Navigator.of(context).pop(result);
  }

  /// Check if can go back
  static bool canGoBack(BuildContext context) {
    return Navigator.of(context).canPop();
  }
}

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState get navigator => navigatorKey.currentState!;

  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigator.pushNamed(routeName, arguments: arguments);
  }

  static Future<dynamic> navigateAndRemoveUntil(
    String routeName, {
    Object? arguments,
  }) {
    return navigator.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static Future<dynamic> navigateAndReplace(
    String routeName, {
    Object? arguments,
  }) {
    return navigator.pushReplacementNamed(routeName, arguments: arguments);
  }

  static void goBack([dynamic result]) {
    return navigator.pop(result);
  }

  static bool canGoBack() {
    return navigator.canPop();
  }
}
