import 'package:cloud_firestore/cloud_firestore.dart';

import 'template.dart';

/// Firestore-backed read/write of templates.
///
/// Two collections of interest, both rooted at the consuming app's
/// configured Firebase project:
///
///   /system_templates/{templateId}      — read-only for everyone,
///                                          managed by the developer
///   /users/{uid}/templates/{templateId} — owner-scoped read/write,
///                                          this user's custom templates
///
/// Apps compose `watchSystem()` and `watchUserCustom()` in their UI
/// layer (Riverpod combines naturally) to render a single template
/// picker. Saves and deletes go through `saveCustom` / `deleteCustom`.
///
/// `Firebase.initializeApp()` MUST have been called by the consumer
/// before any method on this class is invoked. The class doesn't
/// initialise Firebase itself — the consuming app owns the Firebase
/// instance.
class TemplateSyncService {
  TemplateSyncService({required this.uid, FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Firebase Auth uid of the user who "owns" the custom-template
  /// collection. Anonymous Auth users have a uid too — sync works
  /// before the user upgrades to Google Sign-In.
  final String uid;

  final FirebaseFirestore _db;

  static const String systemTemplatesCollection = 'system_templates';
  static const String usersCollection = 'users';
  static const String userTemplatesSubcollection = 'templates';

  CollectionReference<Map<String, dynamic>> get _systemColl =>
      _db.collection(systemTemplatesCollection);

  CollectionReference<Map<String, dynamic>> get _userColl => _db
      .collection(usersCollection)
      .doc(uid)
      .collection(userTemplatesSubcollection);

  // ──────────────────────────────────────────────────────────────────
  // Reads
  // ──────────────────────────────────────────────────────────────────

  /// Stream of system templates the developer has shipped centrally.
  /// Empty list if no docs in /system_templates yet — apps fall back
  /// to in-package SystemTemplates.all in that case.
  Stream<List<Template>> watchSystem() {
    return _systemColl.snapshots().map((snap) {
      return [
        for (final d in snap.docs)
          Template.fromJson({
            ...d.data(),
            'id': d.id,
            'is_custom': false,
          }),
      ];
    });
  }

  /// Stream of THIS user's custom templates.
  Stream<List<Template>> watchUserCustom() {
    return _userColl.snapshots().map((snap) {
      return [
        for (final d in snap.docs)
          Template.fromJson({
            ...d.data(),
            'id': d.id,
            'is_custom': true,
            'owner_uid': uid,
          }),
      ];
    });
  }

  /// One-shot read of the user's custom templates. For first-paint
  /// before the snapshot stream warms up.
  Future<List<Template>> getUserCustom() async {
    final snap = await _userColl.get();
    return [
      for (final d in snap.docs)
        Template.fromJson({
          ...d.data(),
          'id': d.id,
          'is_custom': true,
          'owner_uid': uid,
        }),
    ];
  }

  // ──────────────────────────────────────────────────────────────────
  // Writes (custom templates only — system collection is read-only)
  // ──────────────────────────────────────────────────────────────────

  /// Create or update a custom template. Stamps `updatedAt` with
  /// the current UTC time and forces `isCustom = true` + the current
  /// uid as owner regardless of what the caller provided.
  Future<void> saveCustom(Template template) async {
    final stamped = template.copyWith(
      isCustom: true,
      ownerUid: uid,
      updatedAt: DateTime.now().toUtc(),
    );
    await _userColl.doc(stamped.id).set(stamped.toJson());
  }

  /// Delete one of this user's custom templates. No-op (no exception)
  /// if the doc doesn't exist.
  Future<void> deleteCustom(String templateId) async {
    await _userColl.doc(templateId).delete();
  }
}
