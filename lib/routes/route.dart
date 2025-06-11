import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/inventory/models/InventoryInfo.dart';
import 'package:workshop_management_system/modules/inventory/models/MarketplaceInfo.dart';

//Page of Manage Inventory Module
import '../modules/inventory/views/page/InventoryPage.dart';
import '../modules/inventory/views/page/AddInventoryPage.dart';
import '../modules/inventory/views/page/EditInventoryPage.dart';
import '../modules/inventory/views/page/Marketplace.dart';
import '../modules/inventory/views/page/MarketplaceSaleListingPage.dart';
import '../modules/inventory/views/page/MarketplaceRequestListingPage.dart';
import '../modules/inventory/views/page/SellForm.dart';
import '../modules/inventory/views/page/RequestInventoryForm.dart';
import '../modules/inventory/views/page/SaleDetailsPage.dart';
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
  static const String requestDetails = '/requestDetails';

  
  
  // Initial route
  static const String initial = inventory;
}

class AppRouter {
  // Prevent instantiation
  AppRouter._();
  
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Inventory Module Routes
      case AppRoutes.inventory:
        return MaterialPageRoute(
          builder: (_) => const InventoryPage(),
        );
      
      case AppRoutes.addInventory:
        return MaterialPageRoute(
          builder: (_) => const AddInventoryPage(),
        );
      
      case AppRoutes.editInventory:
        final inventory = settings.arguments as InventoryInfo;
        return MaterialPageRoute(
          builder: (_) => EditInventoryPage(item: inventory),
        );
      
      // Marketplace Module Routes
      case AppRoutes.marketplace:
        return MaterialPageRoute(
          builder: (_) => const Marketplace(),
        );
        
      case AppRoutes.saleListing:
        return MaterialPageRoute(
          builder: (_) => const MarketplaceSaleListingPage(),
        );
        
      case AppRoutes.requestListing:
        return MaterialPageRoute(
          builder: (_) => const MarketplaceRequestListingPage(),
        );
        
      case AppRoutes.sellForm:
      final inventory = settings.arguments as InventoryInfo;
        return MaterialPageRoute(
          builder: (_) => SellForm(item: inventory),
        );
        
      case AppRoutes.requestForm:
        return MaterialPageRoute(
          builder: (_) => const RequestInventoryForm(),
        );
        
      case AppRoutes.saleDetails:
        final saleId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => SaleDetailsPage(saleId: saleId),
        );
        
      case AppRoutes.requestDetails:
        final requestId = settings.arguments as MarketplaceInfo;
        return MaterialPageRoute(
          builder: (_) => RequestDetailsPage(requestItem: requestId),
        );
      
      default:
        // If there is no such named route, return an error page
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Page Not Found'),
            ),
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
    return Navigator.of(context).pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
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
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState get navigator => navigatorKey.currentState!;
  
  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigator.pushNamed(routeName, arguments: arguments);
  }
  
  static Future<dynamic> navigateAndRemoveUntil(String routeName, {Object? arguments}) {
    return navigator.pushNamedAndRemoveUntil(
      routeName, 
      (route) => false,
      arguments: arguments,
    );
  }
  
  static Future<dynamic> navigateAndReplace(String routeName, {Object? arguments}) {
    return navigator.pushReplacementNamed(routeName, arguments: arguments);
  }
  
  static void goBack([dynamic result]) {
    return navigator.pop(result);
  }
  
  static bool canGoBack() {
    return navigator.canPop();
  }
}