# self.umz.ac.ir – reverse-engineering notes

Backend: Jahangostar (فناوران جهان گستر) food automation v9.0.11. ASP.NET Web API + AngularJS 1 SPA + SignalR + IdentityServer3.
Money values are in RIAL (1,000,000 = 100,000 toman). Dates are Jalali strings `1405/08/09`; `MiladiDayDate` is the Gregorian equivalent.

## Auth
- `GET /` -> 302 `/identity/connect/authorize?client_id=D0801C4D8F2A2CD5&redirect_uri=https://self.umz.ac.ir&response_mode=form_post&response_type=id_token token&scope=openid&state&nonce`
- -> `/identity/login?signin=<id>` HTML. Hidden JSON `#modelJson` holds `loginUrl` and `antiForgery {name:"idsrv.xsrf", value}`.
- POST form to `loginUrl`: `username`, `password`, `idsrv.xsrf` (+ `Captcha` when active, + `rememberMe`). The `idsrv.xsrf` cookie is set with the page.
- Captcha: `GET /api/v0/Captcha?isactive=wehavecaptcha` -> `0` = off (currently off). Image at `/api/v0/Captcha?id=<rand>`. Probably turns on after failed attempts.
- Optional OTP: server returns an error message prefixed `2FA <seconds> ...` / `W2FA` / `EX2FA`; the user then submits the 4-digit code as the password `OTP_1234` to the same login URL.
- After login: auto-submitting form POSTs `id_token` + `access_token` to `/`; the server then sets a session cookie.
- All API calls afterwards are cookie-authenticated (no Authorization header in the SPA). Logout: `/Home/Logout`.
- Cookie lifetime and sliding expiry: NOT yet measured.
- Other login paths exist (CAS/SSO via `/Cas/Login`, `/identity/external?provider=OAuth`), not needed.

## API conventions (from `Modules/_services.js`)
- `/api/v0/<Controller>` : GET list / GET `/{id}` / POST / PUT / DELETE (REST style)
- `/api/v1/<Controller>/<Action>` : POST/GET/PUT/DELETE by action name
- Static SPA bundles `/Modules/_app.js`, `_services.js`, `_usercontrollers.js`, `_userdirectives.js` need an authenticated cookie (401 otherwise). Templates are at `/Modules/Jeton/...html`.

## Endpoints relevant to the app
Public (no login):
- `GET /api/v0/CenterInfo`, `GET /api/v0/ActiveNotification`

Authenticated:
- `GET /api/v0/Credit` -> number in rial (can be negative)
- `GET /api/v1/Student/GetCurrent` -> profile (not inspected, personal)
- `GET /api/v1/DateTools/PersianDate` -> `{Date,...}`
- `GET /api/v0/Authentication`, `/api/v1/Authentication/GetLatest?top=N` -> login history
- `GET /api/v0/RolePermissions`
- `GET /api/v0/Reservation?lastdate=<Jalali or empty>&navigation=<0|-7|7>` -> array of 7 days (week view)
  - Day: `DayDate, MiladiDayDate, DayTitle, DayState, DayStateTitle, ActiveDay, Meals[]`
  - Meal: `Id, MealId, MealName (صبحانه/ناهار/شام/سحری/افطاری), MealState, MealStateTitle, CanChangeSelf, FoodCountLimit[{FoodType,PriceType,MaxCount,TotalCount}], FoodTypeMenu[], FoodMenu[], LastReserved[]`
  - Food: `FoodId, FoodName, PictureUrl[], FoodType, Compounds, FoodState, SelfMenu[{SelfId,SelfName,Price,Yarane,ShowPrice,MaxReserveCount,HasDailySale}]`
  - Price: `Price` is full price, `Yarane` the subsidy. Student pays `Price - Yarane` when `PriceType == 2` (subsidised), `PriceType == 1` is free-price.
  - MealState values seen: 0 active (can reserve), 1 already reserved/closed, 4 outside reservation schedule, 5 no program defined, 6 not possible for current day/meal. DayState: 0 active, 2 inactive, 4 holiday, 5 no schedule. (Full enum not confirmed.)
  - `navigation=7` with `lastdate` of the current week start returned only holiday/undefined rows. Future-week availability needs rechecking when the university publishes next week.
- `POST /api/v0/Reservation` body = array of reserve rows for ONE meal:
  `{Row, Id (=Meal.Id), Date, MealId, FoodId, FoodName, SelfId, LastCounts, Counts, Price, SobsidPrice, PriceType, State:0, Type (FoodType), OP:1, OpCategory:1, Provider:1, Saved:0, ...}`
  -> response array of `{StateCode, FoodName, ReserveNumber, Row, Date, MealID, FoodID, PriceType, ID}`. StateCode 0 / 4 seen as success/other; full enum not mapped.
  - Cancelling is also done through this POST (decrease `Counts` below `LastCounts`, `OP`=1, State 2) – exact cancel payload NOT yet captured (needs a real reserve+cancel test).
- `GET /api/v0/Reservation?fromdate=<Jalali>&todate=<Jalali>` -> reserved list (ReservedList page)
- `POST /api/v1/Reservation/GetFoodWithGramazh` {mealId,foodId,selfId,date} -> food with gram weights
- `POST /api/v1/ChangeReserveSelf/Insert` -> move a reservation to another self (dining hall)
- `GET /api/v0/ReservationFinancial` -> used / financial summary (not inspected)
- Food transfer between students: `TransferFoodSale`, `TransferFoodBuy` (api/v0)
- Credit transfer between students: `StudentCreditTransfer` (has captcha)
- Top-up: `IncreaseCredit*` / bank gateway pages (redirect to bank, cannot be automated, out of scope)
- Live updates: SignalR hub `startconnectivityhub` at `/signalr` (negotiate/connect). Events include `FoodReserved`, `RunAlarm`, `AlarmAndClose`.

## Rules observed
- Reservation closes about 24 h before the meal (university notice 1405/07/30), at a configured hour.
- Per-meal caps in `FoodCountLimit` (separate cap for subsidised vs free price).
- No reservation on holidays.
- Account in test was at negative credit; whether reserving is blocked at negative credit is unknown.

## Not yet verified
- Cookie/session lifetime and "remember me" behaviour (`idsrv` persistent cookie).
- Exact cancel payload and the StateCode enum.
- Whether a full week can be reserved at once or the open window is rolling.
- Rate limiting / lockout rules on repeated failed logins.

## Decisions (user)
- Stack: Flutter (Dart). Targets v1: Windows + Android (macOS/Linux/iOS later, not promised).
- UI languages: Persian (default, RTL, Jalali) + English.
- Account has no OTP; password only (keep OTP screen as low-priority fallback).
- v1 scope: login/credential manager/remember me, week view, reserve, cancel, reserved list, balance, auto-reserve rules, spending stats.
- Out of v1: food selling/buying, credit transfer, top-up.
- User will pick one meal for a real reserve+cancel test to capture the cancel payload.

## Live reserve test (2026-11-02)
- POST /api/v0/Reservation with a one-row array for 1405/08/13 breakfast (PriceType 2, Counts 1, Price = Price - Yarane, SobsidPrice = Yarane, Id = Meal.Id (21), Row 1) -> HTTP 200.
- Response is an array of results. Failure case: `State:2, StateCode:3, StateMessage:"موجودی کافی نمی باشد"` (insufficient balance), `ID:-1`, `ReserveNumber:null`. HTTP stays 200, so the app MUST check StateCode/ReserveNumber, not the HTTP status.
- Result fields: Row, ID, Date, MealID, FoodID, FoodType, SelfID, Count, Price, PriceType, SobsidPrice, State, StateCode, StateMessage, ReserveNumber, FinancialInfo[], WalletInfo[].
- Negative balance (-85,000 T) blocks reserving. Nothing was reserved, so the cancel payload is still unverified.
- StateCode known so far: 3 = insufficient balance; 0 and 4 appear in the SPA's success handling (unconfirmed which).
