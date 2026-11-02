# Review checklist (Codex dung file nay de quyet dinh Approve / Request-changes)

Quy tac chung: **chi Approve khi moi muc "Chan merge" deu dat.** Muc "Ghi nhan" khong chan merge, nhung phai duoc ghi trong comment review.

## Chan merge (bat ky muc nao khong dat -> Request-changes)

1. **Dong bo commit.** CI xanh va ket qua `verify/windows-real` deu tuong ung voi commit moi nhat cua PR.
2. **Duong dan duoc bao ve.** Diff co cham vao `.github/**`, `tests/golden/**`, `docs/review-checklist.md`, `docs/workflow.md`, `scripts/verify-windows.ps1`, `CMakePresets.json`
   -> Request-changes ngay, tru khi plan ghi ro checkpoint nay duoc phep doi cac file do va chu repo da duyet.
3. **Test khong bi lam yeu.** Khong xoa/doi ten/vo hieu hoa test, khong noi long nguong sai so, khong them `skip`/`disabled` de CI xanh.
4. **Dung tieu chi nghiem thu cua plan.** Moi tieu chi nghiem thu cua checkpoint co test hoac bang chung tuong ung. Thieu -> Request-changes.
5. **Pham vi.** Chi lam dung 1 checkpoint. Thay doi ngoai plan -> Request-changes (hoac tach PR).
6. **Windows.** Duong dan/chuoi dung UTF-16 (`wchar_t`/`std::filesystem::path`), khong gia dinh `char` la UTF-8; khong tron CRT Debug/Release qua ranh gioi DLL; khong dung API POSIX khong co tren MSVC.
7. **An toan bo nho & vong doi.** Khong UB ro rang (ra ngoai bien, dung sau khi giai phong, race tren du lieu dung chung giua thread render).
8. **Render.** Thay doi so hoc anh co nguong sai so khai bao trong test; golden image chi doi khi plan cho phep, kem ly do.

## Ghi nhan (khong chan merge)

- Test chi pass o lan chay lai thu 2 (nghi flaky): ghi ten test.
- Goi y hieu nang, ten goi, tai cau truc nho.
- Rui ro Windows chua co test bao phu.

## Khi plan co van de

Neu review cho thay plan sai/thieu (khong phai loi cua code): **khong Request-changes cho Muse sua code**. Gan nhan `plan-blocked`, comment ro cho nao cua plan sai, va tao PR sua plan (xem `docs/workflow.md`).
