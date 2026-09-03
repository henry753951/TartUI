# TartUI

TartUI 是一個小型的原生 macOS App，用來查看 Tart 映像檔並管理本機虛擬機。

部分早期互動構想受到 [TartDesk](https://github.com/mohnya-org/TartDesk) 啟發。

[English](README.md) · 繁體中文

## 功能

- 將 OCI 映像檔與可執行的本機虛擬機分開管理，不會讓映像檔出現錯誤的執行狀態。
- 下載 OCI 映像檔，並設定並行數與不安全 Registry 選項。
- 以 OCI／本機來源複製、macOS IPSW、空白 Linux 磁碟或 `.tvm` 封存檔建立 VM。
- 編輯 CPU、記憶體、顯示尺寸、磁碟、MAC 位址與 macOS 序號等設定。
- 儲存每台 VM 的執行選項，支援一鍵執行或開啟完整選項。
- 以清單管理共享目錄與額外磁碟，並使用原生檔案／資料夾選擇器。
- 顯示 IP、網路介面、客體系統、記憶體／磁碟用量與 VM 的本機位置。
- 使用主機原本的 OpenSSH 信任政策，在「終端機」開啟 SSH。
- 支援英文與繁體中文，並跟隨 macOS 的個別 App 語言設定。

## 安全界線

TartUI 不會修改 `~/.ssh/config`、`~/.ssh/known_hosts`、
`StrictHostKeyChecking`、主機網路或 CIDR 信任規則。顯示資訊也不會修改 VM 磁碟內容。

## 系統需求

- macOS 15 或更新版本
- Xcode 26 或更新版本
- 已另外安裝 [Tart](https://github.com/openai/tart)

TartUI 會自動尋找 `/opt/homebrew/bin/tart` 或 `/usr/local/bin/tart`，也可以在
「設定」中選擇其他執行檔。Tart 與 `tart-guest-agent` 不包含在 App 內。

## 開發

```bash
make format
make check
```

也可以直接在 Xcode 開啟 `TartUI.xcodeproj`。`--force-light`、`--force-dark`
與 `--sidebar-hidden` 啟動參數可用於視覺驗證。

專案以 Swift 6、SwiftUI、Observation 與 String Catalog 實作。Tart CLI、參數編碼、
執行選項儲存及主機整合集中在 `Services`，UI 不直接執行 Tart 指令。

## 授權

TartUI 採用 [MIT License](LICENSE)。外部工具與設計參考的授權請見
[第三方聲明](THIRD_PARTY_NOTICES.md)。本專案與 OpenAI 或 Cirrus Labs 無隸屬關係，
也未獲其背書。
