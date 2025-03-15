// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:editto_flutter/utilities/stripe_services.dart';
import 'package:editto_flutter/widgets/show_snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseServices {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<String> signUp({
    required BuildContext context,
    required Map texts,
    required String email,
    required String password,
    required String checkPassword,
    required String name,
  }) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showSnackBar(context, texts['login'][8]);
      return 'fields not filled';
    }
    if (password.length < 6) {
      showSnackBar(context, texts['login'][10]);
      return 'short password';
    }
    if (password != checkPassword) {
      showSnackBar(context, texts['login'][15]);
      return 'passwords not equal';
    }

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await firestore.collection('Users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'subscriptionType': 'trial',
        'subscriptionStartDate': DateTime.now().toString(),
        'subscriptionId': '',
        'subscriptionStatus': 'notSubscribed',
        'customerId': '',
        'shareWith': [],
        'receiveFrom': [],
        'createdAt': DateTime.now().toString(),
      });

      Navigator.pushNamed(context, '/sell');
      return 'success';
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('invalid-email')) {
        errorMessage = texts['login'][20];
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage = texts['login'][22];
      } else {
        errorMessage = "${texts['login'][9]}\n$e";
      }
      showSnackBar(context, errorMessage);
      return e.toString();
    }
  }

  Future<String> logIn(
      {required BuildContext context,
      required Map texts,
      required String email,
      required String password}) async {
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await auth.signInWithEmailAndPassword(email: email, password: password);
        try {
          String? subscription =
              await StripeServices().getCustomerSubscription();
          final docSnapshot = await FirebaseFirestore.instance
              .collection('Users')
              .doc(auth.currentUser!.uid)
              .get();

          List receiveFrom = docSnapshot.data()!['receiveFrom'];
          Navigator.pushNamed(
              context,
              ((subscription == 'trial' || subscription == 'canceled') &&
                      receiveFrom.isEmpty)
                  ? '/sell'
                  : '/dashboard');
        } catch (e) {
          showSnackBar(context, texts['login'][9]);
          return e.toString();
        }

        return 'success';
      } else {
        showSnackBar(context, texts['login'][7]);
        return 'fields not filled';
      }
    } catch (e) {
      String errorMessage = '';
      if (e.toString().contains('invalid-email')) {
        errorMessage = texts['login'][20];
      } else if (e.toString().contains('invalid-credential')) {
        errorMessage = texts['login'][21];
      } else {
        errorMessage = texts['login'][9];
      }
      showSnackBar(context, errorMessage);
      return e.toString();
    }
  }

  Future<String> logOut(context) async {
    try {
      await auth.signOut().then((value) {});

      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> forgotPassowrd(context, texts, email) async {
    await auth.sendPasswordResetEmail(email: email).then((value) {
      showSnackBar(
        context,
        texts['login'][13],
      );
    }).onError((error, stachTrace) {
      showSnackBar(
        context,
        error.toString(),
      );
    });
  }
}
