# Plan bootstrap GitHub — DRAFT, chờ owner duyệt

Ngày: 2026-11-02. Phạm vi của plan này chỉ là đưa quy trình GitHub vào hoạt động.
Chưa có checkpoint triển khai UI, Read, Write hoặc Merge mới.
Muse không bắt đầu thực thi chỉ vì PR nháp này đã được mở.

## Hiện trạng đã kiểm tra

- GitHub `main` tại `98a97cba97c473c8aad378c87d69b11a7c23a1c2` chỉ có workflow/docs/scripts;
  chưa có `CMakeLists.txt` hoặc source sản phẩm. CI dừng ở configure, không phải lỗi test.
- `CODEX_LOGIN=vietnamnguyen-codex`; Muse dùng `vietnamnguyen-muse`.
- Source canonical local: `D:\Vibecode\ffggcomp_project`.
  `D:\Vibecode\ffgg-comp` là archive, không dùng làm nguồn import.
- Local có 148 file trong `source`, 34 file trong `tests`. Đây là số kiểm kê ban đầu,
  không phải chứng nhận phiên bản source; phải lập manifest mới trước import.
- `third_party` local chứa cả Qt SDK khoảng 310 MB: không upload toàn bộ thư mục.
- Baseline sản phẩm là catalog/Properties đã reset trống; source/test node cũ là hồ sơ.
  Đưa source vào Git không cho phép khôi phục node cũ hoặc triển khai node mới.

## CP0 — Khung kết nối và baseline build

### CP0-A: Quy tắc duyệt và merge (PR hiện tại)

Cho phép đổi `.github/CODEOWNERS`, thêm `.github/rulesets/main-owner-only.json`,
đổi `scripts/apply-branch-protection.sh`, `docs/workflow.md` và `docs/plan.md`.
Giữ nguyên yêu cầu CI/test/verify hiện có, không sửa source sản phẩm.

Tiêu chí nghiệm thu:

- CODEOWNERS yêu cầu `vietnamnguyen-owner` duyệt mọi thay đổi plan.
- Hai ruleset bổ sung nhau: `main-protection` không có bypass cho review/check;
  `main-owner-only` chỉ cho user ID `127170901` (owner) cập nhật main qua PR.
- Script áp dụng cả hai rule, dừng nếu API đọc cấu hình lỗi hoặc repo/owner không khớp.
- JSON hợp lệ, script qua kiểm tra cú pháp Bash; chưa tuyên bố rule có hiệu lực trước khi owner áp dụng.
- Owner review bản nháp và quyết định cách bootstrap. PR này chưa đủ điều kiện merge:
  source, CI xanh và verify thực còn thiếu. Không tự tạo ngoại lệ hoặc merge khi CI đỏ.

### CP0-B: Đưa source canonical vào Git (PR riêng, chưa bắt đầu)

Chỉ thực hiện sau khi owner duyệt phạm vi import trong plan. Muse là executor;
Codex đối chiếu manifest, review và verify. Cần xác định cách cung cấp snapshot local
cho Muse trước khi executor bắt đầu; không giả định Muse đọc được ổ D:.

Phạm vi dự kiến: `CMakeLists.txt`, `source/**`, `tests/**`, các header/source/license
third-party thực sự được build tham chiếu, `.gitignore`, hồ sơ reset và manifest SHA-256.
Không đưa `third_party/Qt`, build, release, cache, credentials hoặc toàn bộ evidence/history lên Git.
Kiểm tra license/nguồn của các file vendored trước khi publish vào repo public.

Tiêu chí nghiệm thu:

- Danh sách file và SHA-256 nguồn/đích khớp; mọi khác biệt được liệt kê để owner duyệt.
- Không sửa hành vi engine/node, không kích hoạt lại node cũ; test reset vẫn được đăng ký.
- Tất cả nguồn/fixture được CMake/test tham chiếu có trong snapshot; không phụ thuộc đường dẫn máy cá nhân.
- Ghi rõ dependency cần tải (Qt, OCIO, Python), phiên bản và cách tái tạo trên máy sạch.
- Không tuyên bố UI hoặc ba node được nghiệm thu từ việc build baseline thành công.

### CP0-C: CI tái lập được (PR riêng)

Cho phép đổi `.github/workflows/ci.yml` và cấu hình dependency/build sau khi owner
duyệt chi tiết. Không nới test, không tự đổi golden và không dùng stub OCIO để chứng nhận màu.

Tiêu chí nghiệm thu:

- Runner/compiler khớp, dependency được cài có phiên bản; GUI và engine build Debug/Release.
- CTest thực sự tìm được và chạy test; `--no-tests=error` còn nguyên.
- Golden gate chỉ được ghi là đã có khi test so ảnh thật, fixture/ngưỡng và artifact tương ứng tồn tại.
- `ci-gate` xanh ở commit PR được review; log ghi cấu hình và các test chạy lại lần hai.

### CP0-D: Verify Windows và kích hoạt bảo vệ (owner + Codex)

Chưa chạy build bằng tài khoản admin hiện tại. Chuẩn bị standard user riêng và
`C:\verify` theo workflow; tách credential đọc/build khỏi credential có quyền post status.
Review script trước khi chạy: đầu vào PR/SHA, giới hạn đường dẫn xóa, bắt lỗi lệnh
ngoài, môi trường build, labels thực sự có test, log và commit bị thay giữa chừng.
Mọi thay đổi script verify phải được owner duyệt qua PR riêng.

Tiêu chí nghiệm thu:

- Verify đúng SHA, tài khoản không elevated; có log GPU/driver/OS và kết quả Debug/Release.
- Có test thực thuộc nhóm GPU/DPI/performance cần máy thật; không gắn nhãn cho test thường để làm xanh.
- Verify lỗi hoặc không có test tương ứng không được post success; head đổi làm bằng chứng cũ mất hiệu lực.
- Owner áp dụng cả hai ruleset bằng credential admin của chính owner.
- API xác nhận ruleset active, các check bắt buộc và code-owner review có hiệu lực;
  kiểm chứng bằng PR thử không đổi sản phẩm, lưu bằng chứng owner merge / agent bị chặn.

## Cổng trước plan sản phẩm

CP0 chưa hoàn thành thì chưa giao checkpoint sản phẩm. Plan sản phẩm được mở ở PR sau,
dựa trên UI/hành vi đã được owner chốt và nguồn tài liệu hiện hành; không suy ra approval
từ nhãn APPROVED trong bản tổng hợp hoặc từ kết quả CI.
