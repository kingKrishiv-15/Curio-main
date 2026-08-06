# Curio Mermaid Architecture Maps

These diagrams are the implementation map for the Flutter version of Curio.
They describe the intended production application rather than the earlier
React/Vite prototype. Firebase is the selected backend platform: Firebase
Authentication, Cloud Firestore, Cloud Functions, Cloud Storage, Cloud
Messaging, App Check, Crashlytics and Performance Monitoring.

## Diagram index

1. `1_functional_and_non_functional_requirements.mmd`
2. `2_high_level_system_architecture.mmd`
3. `3_parent_onboarding_and_learning_sequence.mmd`
4. `4_daily_squeeze_sequence.mmd`
5. `5_offline_sync_and_reconnection_sequence.mmd`
6. `6_firestore_collection_model.mmd`
7. `7_learning_session_state_machine.mmd`
8. `8_simplified_curio_app_flow.mmd`

The diagrams use Mermaid syntax and can be opened in Mermaid Live Editor or
any Mermaid-enabled IDE. Keep them updated when an implementation decision
changes an API boundary, lifecycle, or persistent entity.

## Firebase data boundary

Flutter may read child-safe, published and parent-owned documents directly
when Firestore Security Rules allow it. Any operation that validates an answer
or changes mastery, XP, a streak, a reward, protected content or an audit trail
must run in a callable Cloud Function using an Admin SDK transaction.

The entity diagram is a conceptual Firestore collection model. Its references
describe application relationships; Firestore does not enforce foreign keys.
Frequently read summaries should be deliberately denormalized and maintained
by trusted functions.
