# Fast-Pos architecture

## Layers

| Layer | Path | Responsibility |
| --- | --- | --- |
| **Domain** | `lib/domain/` | Entities, value objects (`bill_submission.dart`), repository interfaces — **no Flutter** |
| **Application** | `lib/application/` | Use cases (`SubmitBillUseCase`, `ObserveBillsUseCase`, …) — orchestration only |
| **Data** | `lib/data/` | Supabase repository implementations, mappers, **`BillPdfGenerator`** (PDF + HTTP) |
| **Presentation** | `lib/presentation/<feature>/` | `bloc/` (Bloc + events + state), `view/` (pages), `widgets/` (feature UI parts) |
| **Core** | `lib/core/` | Theme, router, spacing, shared errors, `deferToNextEventLoop` |

## State management (MVVM-style)

- **View** = `StatelessWidget` / thin `StatefulWidget` under `view/` — layout, `BlocBuilder` / `BlocListener`, no Supabase.
- **ViewModel** = `Bloc<Event, State>` — explicit events, immutable states; orchestration calls **use cases** or subscribes to repository streams.
- **Bill generation** uses two blocs: `BillDraftBloc` (line items) + `BillSubmissionBloc` (persist + PDF via `SubmitBillUseCase`).

## Navigation

- **`go_router`** in `lib/core/router/app_router.dart`; auth redirects read `AuthBloc` state.

## Dependency rule

- UI and Blocs depend on **repository interfaces** and **use cases**, not `Supabase.instance` (except `lib/data/`).

## Legacy screens

- `lib/screens/` may re-export `presentation/.../view/` for backwards compatibility during migration.
