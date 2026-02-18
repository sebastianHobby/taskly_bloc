# Guardrail To Invariant Map

Maps executable guardrails to normative invariant areas.

| Guardrail script | Invariants covered |
|---|---|
| `tool/no_local_package_src_deep_imports.dart` | `INV-LAYER-002` |
| `tool/no_layering_violations.dart` | `INV-LAYER-001`, `INV-PRES-001` |
| `tool/no_powersync_local_upserts.dart` | `INV-SYNC-002` |
| `tool/no_datetime_now_in_domain_data.dart` | `INV-TIME-001` |
| `tool/no_datetime_now_in_presentation.dart` | `INV-TIME-001` |
| `tool/no_wall_clock_in_tests.dart` | `INV-TEST-003` |
| `tool/no_raw_test_wrappers.dart` | `INV-TEST-002` |
| `tool/no_pump_and_settle_in_widget_tests.dart` | `INV-TEST-002` |
| `tool/no_unseeded_subjects_in_widget_tests.dart` | `INV-TEST-003` |
| `tool/no_test_directory_tag_violations.dart` | `INV-TEST-004` |
| `tool/no_expired_arch_exceptions.dart` | Exception policy compliance |
| `tool/validate_id_generator_table_registration.dart` | `INV-SYNC-001` |
| `tool/validate_supabase_schema_alignment.dart` | `INV-SYNC-001` (pre-push guard via `git_hooks.dart`) |

## Runner

Central runner: `tool/guardrails.dart`

## Escape hatch policy

If any `ignore-*-guardrail` comment is used, it must reference a tracked exception doc under `doc/architecture/exceptions/` with owner and expiry.
