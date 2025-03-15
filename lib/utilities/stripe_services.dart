// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:editto_flutter/utilities/firebase_services.dart';
import 'package:editto_flutter/widgets/show_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeServices {
  final pubKey =
      'pk_live_51QCldWAGNdCA2ykKGSMmM4gGiQfL9UlAkXXjQUOoVkQ0OO768nVX1h4X2hYekZ3UIy9bvEEl0Xt8WJiRQvNjNork006AOz7vCv';
  final secKey =
      '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';

  final soloBRLId = 'prod_RnsWVJFRteeGJJ';
  final soloBRLprice = 'price_1QuGlKAGNdCA2ykKoU1AzcFl';
  final teamBRLId = 'prod_RnsWjVr6T0VzQQ';
  final teamBRLprice = 'price_1QuGlGAGNdCA2ykK3SRkHwqI';
  final soloUSDId = 'prod_RnsWOjYQOwipaX';
  final soloUSDprice = 'price_1QuGlDAGNdCA2ykKOXnUZvC8';
  final teamUSDId = 'prod_RnsWNCXoL6AvNY';
  final teamUSDprice = 'price_1QuGl8AGNdCA2ykK65PhzRd7';

  String soloBRLUrl = 'https://buy.stripe.com/aEUbMw4QY7UL7yE144';
  String soloUSDUrl = 'https://buy.stripe.com/dR62bW2IQej9aKQ4gi';
  String teamBRLUrl = 'https://buy.stripe.com/4gw03OgzG4Iz2ek4gh';
  String teamUSDUrl = 'https://buy.stripe.com/eVa17S1EMcb16uA9AD';

  Future<dynamic> createCustomer(
      BuildContext context, Map texts, String name, String email) async {
    try {
      final customerResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/customers'),
        headers: {
          'Authorization': 'Bearer $secKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'name': name,
          'email': email,
        },
      );

      return jsonDecode(customerResponse.body)['id'];
    } catch (e) {
      showSnackBar(context, texts['sell'][0]);
      return e.toString();
    }
  }

  Future<List?> createPaymentIntent(
      BuildContext context, Map texts, String customerId, String planId) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer $secKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'customer': customerId,
        'amount': planId == soloBRLId
            ? '990'
            : planId == teamBRLId
                ? '1490'
                : planId == soloUSDId
                    ? '490'
                    : '990',
        'currency':
            (planId == soloBRLId || planId == teamBRLId) ? 'brl' : 'usd',
        'setup_future_usage': 'off_session',
        'payment_method_types[]': 'card',
      },
    );

    if (response.statusCode == 200) {
      final clientSecret = jsonDecode(response.body)['client_secret'];
      final intentId = jsonDecode(response.body)['id'];
      return [clientSecret, intentId];
    } else {
      showSnackBar(context, texts['sell'][0]);
      if (kDebugMode) {
        print("Erro ao criar o PaymentIntent: ${response.body}");
      }
      return null;
    }
  }

  Future<void> showPaymentSheet(BuildContext context, Map texts,
      String clientSecret, String customerId, ThemeMode theme) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'StockChef',
          customerId: customerId,
          style: theme,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (kDebugMode) {
        print("Pagamento realizado com sucesso!");
      }
    } on StripeException catch (e) {
      showSnackBar(context, texts['sell'][0]);
      if (kDebugMode) {
        print("Erro no pagamento: $e");
      }
    } catch (e) {
      showSnackBar(context, texts['sell'][0]);
      if (kDebugMode) {
        print("Erro inesperado: $e");
      }
    }
  }

  Future<void> retrieveAndAttachPaymentMethod(
      String paymentIntentId, String customerId) async {
    final response = await http.get(
      Uri.parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId'),
      headers: {
        'Authorization': 'Bearer $secKey',
      },
    );

    if (response.statusCode == 200) {
      final paymentMethodId = jsonDecode(response.body)['payment_method'];

      await attachPaymentMethodToCustomer(paymentMethodId, customerId);
    } else {
      if (kDebugMode) {
        print("Erro ao recuperar PaymentIntent: ${response.body}");
      }
    }
  }

  Future<void> attachPaymentMethodToCustomer(
      String paymentMethodId, String customerId) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/customers/$customerId'),
      headers: {
        'Authorization': 'Bearer $secKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'invoice_settings[default_payment_method]': paymentMethodId,
      },
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print("Método de pagamento associado ao cliente com sucesso.");
      }
    } else {
      if (kDebugMode) {
        print("Erro ao associar método de pagamento: ${response.body}");
      }
    }
  }

  Future<String?> createSubscription(BuildContext context, Map texts,
      String customerId, String priceId, String planId) async {
    final trialEnd =
        DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch ~/
            1000;
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/subscriptions'),
      headers: {
        'Authorization': 'Bearer $secKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'customer': customerId,
        'items[0][price]': priceId,
        'trial_end': trialEnd.toString(),
      },
    );

    if (response.statusCode == 200) {
      final subscriptionId = jsonDecode(response.body)['id'];
      FirebaseFirestore.instance
          .collection('Users')
          .doc(FirebaseServices().auth.currentUser!.uid)
          .update({
        'subscriptionId': subscriptionId,
        'subscriptionType':
            (planId == soloBRLId || planId == soloUSDId) ? 'solo' : 'team',
        'subscriptionStatus': 'active',
      });
      if (kDebugMode) {
        showSnackBar(context, texts['sell'][1]);
        print("Assinatura criada com sucesso: $subscriptionId");
      }
      return subscriptionId;
    } else {
      if (kDebugMode) {
        showSnackBar(context, texts['sell'][0]);
        print("Erro ao criar assinatura: ${response.body}");
      }
      return null;
    }
  }

  Future<String?> getCustomerIdByEmail(String email) async {
    final response = await http.get(
      Uri.parse('https://api.stripe.com/v1/customers?email=$email'),
      headers: {
        'Authorization': 'Bearer $secKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['data'].isNotEmpty) {
        return data['data'][0]['id'];
      }
    } else {
      if (kDebugMode) {
        print("Cliente não possui assinatura.");
      }
    }
    return null;
  }

  Future<String?> getActiveSubscriptionId(String customerId) async {
    final response = await http.get(
      Uri.parse('https://api.stripe.com/v1/subscriptions?customer=$customerId'),
      headers: {
        'Authorization': 'Bearer $secKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      for (var subscription in data['data']) {
        if (subscription['status'] == 'active' ||
            subscription['status'] == 'trialing' ||
            subscription['status'] == 'past_due') {
          return subscription['id'];
        }
      }
    } else {
      if (kDebugMode) {
        print("Nenhuma assinatura encontrada.");
      }
    }
    return null;
  }

  Future<String?> getPlanId(String subscriptionId) async {
    final response = await http.get(
      Uri.parse('https://api.stripe.com/v1/subscriptions/$subscriptionId'),
      headers: {
        'Authorization': 'Bearer $secKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    if (response.statusCode == 200) {
      dynamic subInfo = jsonDecode(response.body);
      if (subInfo != null && subInfo['items']['data'].isNotEmpty) {
        return subInfo['items']['data'][0]['price']['product'];
      }

      return null;
    } else {
      if (kDebugMode) {
        print("Erro ao buscar assinatura: ${response.body}");
      }
      return null;
    }
  }

  Future<String?> getCustomerSubscription() async {
    String userSubscriptionType = 'not logged';
    String? userStripeId = await StripeServices()
        .getCustomerIdByEmail(FirebaseServices().auth.currentUser!.email!);

    if (userStripeId == null) {
      FirebaseFirestore.instance
          .collection('Users')
          .doc(FirebaseServices().auth.currentUser!.uid)
          .update({'subscriptionId': '', 'subscriptionType': 'trial'});
    } else {
      String? subscriptionId =
          await StripeServices().getActiveSubscriptionId(userStripeId);
      if (subscriptionId == null) {
        FirebaseFirestore.instance
            .collection('Users')
            .doc(FirebaseServices().auth.currentUser!.uid)
            .update({'subscriptionId': '', 'subscriptionType': 'trial'});
      } else {
        String? planId = await StripeServices().getPlanId(subscriptionId);
        if (planId == null) {
          FirebaseFirestore.instance
              .collection('Users')
              .doc(FirebaseServices().auth.currentUser!.uid)
              .update({'subscriptionId': '', 'subscriptionType': 'trial'});
        } else {
          final docSnapshot = await FirebaseServices()
              .firestore
              .collection('Users')
              .doc(FirebaseServices().auth.currentUser!.uid)
              .get();
          Map? userInfo = docSnapshot.data();
          if (userInfo!['subscriptionStatus'] == 'canceled') {
            FirebaseFirestore.instance
                .collection('Users')
                .doc(FirebaseServices().auth.currentUser!.uid)
                .update({
              'subscriptionId': '',
              'subscriptionStatus': 'notSubscribed',
              'subscriptionType': 'trial'
            });
          } else {
            FirebaseFirestore.instance
                .collection('Users')
                .doc(FirebaseServices().auth.currentUser!.uid)
                .update({
              'subscriptionId': subscriptionId,
              'subscriptionType': (planId == StripeServices().soloBRLId ||
                      planId == StripeServices().soloUSDId)
                  ? 'solo'
                  : (planId == StripeServices().teamBRLId ||
                          planId == StripeServices().teamUSDId)
                      ? 'team'
                      : 'trial',
              'subscriptionStatus': (planId == StripeServices().soloBRLId ||
                      planId == StripeServices().soloUSDId)
                  ? 'active'
                  : (planId == StripeServices().teamBRLId ||
                          planId == StripeServices().teamUSDId)
                      ? 'active'
                      : 'notSubscribed',
            });
          }
        }
      }
    }
    final docSnap = await FirebaseServices()
        .firestore
        .collection('Users')
        .doc(FirebaseServices().auth.currentUser!.uid)
        .get();
    var userInfo = docSnap.data();
    if (userInfo!['subscriptionStatus'] == 'canceled') {
      FirebaseFirestore.instance
          .collection('Users')
          .doc(FirebaseServices().auth.currentUser!.uid)
          .update({'subscriptionId': '', 'subscriptionType': 'trial'});
    }
    final docSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(FirebaseServices().auth.currentUser!.uid)
        .get();

    userSubscriptionType = docSnapshot.data()!['subscriptionType'];
    return userSubscriptionType;
  }

  Future<void> cancelSubscription(
      BuildContext context, Map texts, String subscriptionId) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/subscriptions/$subscriptionId'),
      headers: {
        'Authorization': 'Bearer $secKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'cancel_at_period_end': 'true',
      },
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        FirebaseFirestore.instance
            .collection('Users')
            .doc(FirebaseServices().auth.currentUser!.uid)
            .update({
          'subscriptionId': '',
          'subscriptionType': 'trial',
          'subscriptionStatus': 'canceled',
        });
        print("Assinatura cancelada com sucesso.");
        showSnackBar(context, texts['sell'][2]);
      }
    } else {
      if (kDebugMode) {
        showSnackBar(context, texts['sell'][0]);
        print("Erro ao cancelar a assinatura: ${response.body}");
      }
    }
  }

  
 }
