Context: Flutter gym app "Apex" (UI done, mock data). A Laravel API now exists and is tested.
Read docs/api-routes.json, docs/API_DESIGN.md, docs/api-resources/ (exact JSON shapes) and docs/api-requests/
(exact validation rules). Do NOT delete or redesign any UI. Keep the mock data files.

STEP A (do this now): infrastructure + auth + Profile + Training only.
1. Add dependencies: dio, flutter_secure_storage. Keep existing state management (setState).
2. lib/core/api/: ApiClient (dio) with baseUrl config: Android emulator http://10.0.2.2:8000/api,
   iOS simulator/desktop http://127.0.0.1:8000/api, overridable constant for a real device.
   Interceptor adds Authorization Bearer token and Accept: application/json.
   Handle 401 (clear token, go to login), validation errors (422 -> field errors), network errors.
   Responses use the envelope {"data":..., "meta":..., "message":...}.
3. TokenStorage with flutter_secure_storage.
4. Login and Register screens in the existing app style; app start checks for a token and goes to
   Login or Hub. Add a logout action in the profile screen.
5. Repositories with an abstract interface + Mock implementation (wrapping existing mock data) +
   Api implementation, switched by one flag (useMockData) in a config file:
   - ProfileRepository: GET/PUT /me, goals (GET/POST/PATCH/DELETE), measurements (GET/POST), GET /me/dashboard
   - TrainingRepository: GET /exercises, /training/programs, /training/programs/{id}, POST /me/session-logs,
     GET /me/session-logs, GET /me/training-progress
6. Add fromJson/toJson to the models involved. Map API enums (snake_case English like mass_gain,
   beginner) to the existing Dart enums, and keep the French display labels in the UI.
   Dates: parse ISO strings to DateTime; send completedAt as a UTC ISO-8601 string with Z.
7. Wire HubScreen (dashboard), ProfileModuleScreen and TrainingModuleScreen to the repositories with
   loading, error (with retry) and empty states. The session player must POST the session log when a
   workout is finished: sessionId, programId, completedAt, durationMin, highlight,
   sets[{exerciseId, setNumber, reps, loadKg, kind}].
8. Run flutter pub get and flutter analyze and fix errors. Do not start Nutrition, Coaches or Shop.
Test account: lina.moreau@apex.app / Password123!
At the end list the files changed and how to run against the API.
