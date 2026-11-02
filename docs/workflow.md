# Workflow v4: Codex lap plan + review, Muse thuc thi

## 1. Vai tro va quyen (nguyen tac: moi ben chi co dung quyen can thiet)

| Ben | Tai khoan | Quyen | Khong duoc |
|---|---|---|---|
| Ban | tai khoan chu repo | admin, merge | |
| Muse | tai khoan/bot rieng | Contents RW, Pull requests RW (nhanh `cp*`) | commit len `main`; post commit status; sua duong dan trong CODEOWNERS ma khong duoc ban duyet |
| Codex | tai khoan/bot rieng | doc code, review, post status `verify/windows-real`, mo PR plan | sua code san pham |

**Bat buoc dung tai khoan KHAC nhau.** GitHub khong cho tac gia PR tu approve PR cua minh; neu Muse push bang tai khoan cua ban thi CODEOWNERS se khoa ca ban.
Dung fine-grained token, moi ben mot token. Token cua Muse **khong** co quyen "Commit statuses: write".

## 2. Luong va cong chan (khong cong nao do ben duoc kiem tra tu dat)

1. Ban dat muc tieu.
2. Codex lap plan (checkpoint + task + **tieu chi nghiem thu kiem chung duoc**) -> PR sua `docs/plan.md` -> ban duyet va merge.
3. Muse lam 1 checkpoint tren nhanh `cp*` -> mo PR.
4. **CI (hosted, windows-latest + MSVC):** build Debug + Release, ctest, golden-image compare. Check bat buoc: `ci-gate`.
5. Ban goi "check" **khi CI da xanh**.
6. **Verify tren may Windows that:** `scripts/verify-windows.ps1`. Check bat buoc: `verify/windows-real`. That bai -> ket qua tu thanh "chua qua".
7. Codex review theo `docs/review-checklist.md` -> Approve / Request-changes (trang thai GitHub).
8. Request-changes -> Muse tu sua (toi da 2 vong), push lai -> quay ve buoc 4.
9. Merge chi khi: `ci-gate` xanh + `verify/windows-real` xanh + Approve **dung commit moi nhat** + CODEOWNERS duyet neu cham duong dan duoc bao ve.
10. Codex mo PR cap nhat plan -> ban merge -> checkpoint tiep theo.

## 3. CI va "Windows that": moi ben lam gi

| | CI (hosted) | Windows that |
|---|---|---|
| Muc dich | Tai lap duoc, nhanh, chay moi push | Cai CI khong co |
| Noi dung | build Debug/Release, ctest, golden compare | GPU that, driver, DPI, hieu nang (ctest -L `golden|gpu|dpi|perf`) |
| Ai chay | GitHub Actions | Codex tren may rieng, tai khoan han quyen |
| Dau ra | check `ci-gate`, artifact log + anh diff | check `verify/windows-real`, comment co log + GPU/driver |

Neu mot muc khong that su can may that thi dua no ve CI.

## 4. Tran va loi thoat

| Tinh huong | Gioi han | Khi cham gioi han |
|---|---|---|
| CI do lien tiep | 3 lan (`ci-failure-cap.yml`) | nhan `needs-human`, Muse dung |
| Review-fix | 2 vong sua; lan Request-changes thu 3 la dung (`review-round-cap.yml`) | nhan `needs-human`, Muse dung |
| Test flaky | chay lai 1 lan (`--repeat until-pass:2`) | pass o lan 2 van duoc ghi nhan, khong am tham bo qua |
| Verify that bai | khong tu retry | Request-changes kem log |

**Luat cho Muse:** neu PR co nhan `needs-human` hoac `plan-blocked` thi **khong push them**, chi cho. Bo nhan la quyen cua ban.

## 5. Giao thuc "plan sai/thieu giua chung"

1. Muse dung, gan nhan `plan-blocked`, comment vao PR theo mau:
   - Checkpoint / task nao
   - Plan noi gi, thuc te gap gi
   - De xuat (neu co)
2. Codex mo **PR sua `docs/plan.md`** (khong sua truc tiep tren main). Ban duyet va merge.
3. Sau khi PR plan duoc merge, Codex go nhan `plan-blocked`; Muse `rebase` nhanh `cp*` len `main` moi roi lam tiep.
4. PR plan khong duoc tu Codex approve; ban la nguoi duyet duy nhat.

**Checklist ban dung khi duyet PR plan** (vi Codex vua viet plan vua review theo plan):
- Moi tieu chi nghiem thu co the kiem chung bang test hoac bang chung do duoc?
- Moi checkpoint nho du de 1 PR?
- Co noi ro checkpoint nao duoc phep doi `tests/golden/**` hoac file workflow khong?
- Rui ro Windows/render cua checkpoint da duoc nhac toi?

## 6. Co lap may verify

Code do agent sinh ra (ke ca `CMakeLists.txt`, script build) chay duoc lenh tuy y. Toi thieu:

- Tai khoan Windows **standard user** rieng (vd. `verify`), khong phai admin. Script tu choi chay neu bi nang quyen.
- Thu muc lam viec `C:\verify`, chi tai khoan `verify` co quyen ghi. Tai khoan nay khong co quyen doc profile/khoa SSH/token cua ban.
- Dang nhap `gh` bang token **chi doc code** (+ `statuses:write` va `issues:write` rieng cho Codex de post status va comment ket qua). Khong de credential cua ban tren may nay.
- Muon manh hon: chay trong VM (GPU passthrough neu can kiem GPU that) hoac Windows Sandbox (vGPU han che, khong thay the GPU that).

## 7. Rui ro con lai (da biet, chua xoa het)

- Ai co quyen go nhan `needs-human` thi vuot duoc tran; giu quyen do o ban.
- Test flaky chay lai 1 lan co the che mot phan loi ngau nhien.
- Hai cong (Codex lap plan, Codex review) cung mot "nguoi": phan bien that su chi con ban o buoc duyet PR plan.
- CI hosted khong co GPU: loi chi hien tren GPU/driver cu the co the lot qua ca CI.

## 8. Cai dat (lam theo thu tu)

1. Copy cac file vao repo, thay `@OWNER` trong `.github/CODEOWNERS`.
2. Dat repo variable `CODEX_LOGIN` (Settings > Secrets and variables > Actions > Variables).
3. Chinh `ci.yml` cho khop build that (generator, ten test, thu muc `build/golden-diff`).
4. Chinh 3 bien "project-specific" trong `scripts/verify-windows.ps1`; chay thu bang `-Pr <so>` khong co `-PostStatus`.
5. Dat label cho test can may that trong CMake, khop voi regex `$RealMachineTests` trong script (vd. `set_tests_properties(... PROPERTIES LABELS "golden;gpu;dpi;perf")`).
6. Chay `./scripts/apply-branch-protection.sh OWNER/REPO` **sau khi** PR dau tien da co `ci-gate` va `verify/windows-real` (de GitHub nhan ra ten check).
   Luu y: ruleset tren repo private can goi tra phi cua GitHub.
7. Sanitizer (phase 2, sau checkpoint thu dau tien): them job ASan cho MSVC vao
   `ci.yml` (`/fsanitize=address` o ca compile lan link; chu y MSVC khong cho dung
   chung voi `/RTC1` nen phai viet lai `CMAKE_CXX_FLAGS_DEBUG` thay vi cong them),
   roi dua job vao `needs` cua `ci-gate`.
