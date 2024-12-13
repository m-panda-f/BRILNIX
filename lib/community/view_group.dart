import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupDetailsScreen extends StatelessWidget {
  final String groupId;

  const GroupDetailsScreen({Key? key, required this.groupId}) : super(key: key);

  // Join group functionality without showing any UI
  Future<void> joinGroup(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in. Please log in to join.')),
      );
      return;
    }

    try {
      final groupDoc = FirebaseFirestore.instance.collection('groups').doc(groupId);

      // Check if the user is already a member before attempting to add
      final groupSnapshot = await groupDoc.get();
      final groupData = groupSnapshot.data();
      if (groupData == null || groupSnapshot.exists == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group not found.')),
        );
        return;
      }

      final members = List<String>.from(groupData['members']);

      if (members.contains(user.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are already a member of this group.')),
        );
        return;
      }

      // Add user to group
      await groupDoc.update({
        'members': FieldValue.arrayUnion([user.uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have successfully joined the group!')),
      );

      // Optionally, navigate back or to another screen after joining
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join group: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // The widget is only used for calling joinGroup, no UI elements are built.
    joinGroup(context); // Automatically call joinGroup
   return const Scaffold(); // Return an empty scaffold`
  }
}
