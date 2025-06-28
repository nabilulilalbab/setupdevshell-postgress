Ini merupakan rangkuman lengkap dari awal hingga akhir — resep final untuk membangun environment pengembangan Go + PostgreSQL yang ideal menggunakan Nix, berdasarkan metode persis yang telah terbukti berhasil bagi Anda. Simpan panduan ini sebagai "blueprint" utama untuk proyek-proyek Anda ke depannya.

---

---

### **Panduan Lengkap: Membangun Proyek Go + PostgreSQL dengan Nix Flakes & Devshell**

### **Tujuan Utama**

Membangun sebuah environment pengembangan yang sepenuhnya reproducible dan mandiri. Setiap anggota tim (atau Anda di perangkat berbeda) dapat menjalankan proyek ini hanya dengan beberapa perintah, dengan jaminan bahwa semua tools dan layanan akan menggunakan versi yang sama persis dan konfigurasi yang langsung bekerja.

---

### **Bagian 1: Memulai Proyek dari Template Resmi**

Langkah awal terbaik adalah memulai dari template `numtide/devshell`.

1. **Membuat Proyek Baru:**

   ```bash
   nix flake new -t "github:numtide/devshell" proyek-saya

   ```

2. **Masuk ke Folder Proyek:**

   ```bash
   cd proyek-saya

   ```

3. **Ubah `flake.nix` untuk Versi Paket Terbaru:**

   Langkah krusial pertama adalah mengganti isi `flake.nix` agar kita bisa memakai versi terbaru dari Go, PostgreSQL, dan lainnya. Gantilah seluruh isi file tersebut dengan konfigurasi di bawah ini:

   **Isi Akhir `flake.nix`:**

   ```nix
   {
     description = "Go + Postgres Final Dev Environment";

     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
       devshell.url = "github:numtide/devshell";
       devshell.inputs.nixpkgs.follows = "nixpkgs";
       flake-utils.url = "github:numtide/flake-utils";
       flake-utils.inputs.nixpkgs.follows = "nixpkgs";
       flake-compat = {
         url = "github:edolstra/flake-compat";
         flake = false;
       };
     };

     outputs = { self, flake-utils, devshell, nixpkgs, ... }:
       flake-utils.lib.eachDefaultSystem (system:
         let
           pkgs = import nixpkgs {
             inherit system;
             overlays = [ devshell.overlays.default ];
           };
         in
         {
           devShells.default = pkgs.devshell.mkShell {
             imports = [ (pkgs.devshell.importTOML ./devshell.toml) ];
           };
         });
   }

   ```

---

### **Bagian 2: Mengonfigurasi `devshell.toml` (Pusat Kontrol Anda)**

Ini adalah file tempat Anda mendefinisikan semua isi dari environment pengembangan Anda. Ganti seluruh konten `devshell.toml` hasil template dengan konfigurasi final berikut:

**Isi Akhir `devshell.toml`:**

```toml
# Konfigurasi untuk devshell

[devshell]
# Paket yang hanya perlu tersedia di PATH, seperti Language Server untuk editor.
packages = [
  "gopls"
]
# Kostumisasi tampilan prompt shell (opsional).
#prompt = " (proyek-go) λ "
# Nonaktifkan pesan selamat datang default (opsional).
#motd = ""

# Daftar perintah utama yang akan tampil di menu.
[[commands]]
package = "go"
help = "Go Programming Language"

[[commands]]
package = "postgresql_16"
help = "PostgreSQL server & client tools"

# Shortcut untuk koneksi ke database 'korteks'.
[[commands]]
name = "db"
help = "Connect to the 'korteks' database"
command = "psql -h \"$PWD/.postgres-data\" -d korteks"

# Menentukan DATABASE_URL untuk digunakan oleh aplikasi Go.
[[env]]
name = "DATABASE_URL"
value = "postgres://korteks@localhost:5432/korteks?sslmode=disable"

# Menjalankan PostgreSQL sebagai layanan latar belakang.
[serviceGroups.database]
description = "Menjalankan database PostgreSQL di latar belakang"
[serviceGroups.database.services.postgres]
# Gunakan path absolut dari $PWD untuk keandalan.
command = "postgres -D $PWD/.postgres-data -k $PWD/.postgres-data"

```

---

### **Bagian 3: Menyiapkan Database & Aplikasi (Dilakukan Sekali)**

Langkah-langkah berikut hanya perlu dilakukan satu kali setiap kali membuat proyek baru.

1. **Masuk ke Environment:**

   ```bash
   nix develop

   ```

   Prompt Anda akan berubah menjadi `(proyek-go) λ`.

2. **Persiapan Folder dan Inisialisasi Database Cluster:**

   ```bash
   # Di dalam devshell:
   (proyek-go) λ mkdir ./.postgres-data
   (proyek-go) λ initdb -D ./.postgres-data
   (proyek-go) λ echo ".postgres-data/" >> .gitignore

   ```

3. **Buat Database 'korteks':**

   Proses ini memerlukan server PostgreSQL aktif untuk sementara waktu. Jalankan perintah-perintah berikut satu per satu:

   ```bash
   # Aktifkan server di background
   (proyek-go) λ database:start &

   # Tunggu beberapa detik untuk memastikan server siap
   (proyek-go) λ sleep 3

   # Buat database 'korteks'. Perintah 'createdb' perlu flag -h
   (proyek-go) λ createdb -h "$PWD/.postgres-data" korteks

   # Matikan server jika sudah selesai
   (proyek-go) λ database:stop

   ```

4. **Inisialisasi Proyek Go dan Setup Awal:**

   ```bash
   # Buat file main.go dan isi dengan kode aplikasi
   (proyek-go) λ touch main.go
   # (Tempel kode aplikasi Anda)

   # Inisialisasi Go module
   (proyek-go) λ go mod init proyek-saya
   (proyek-go) λ go get github.com/jackc/pgx/v5

   ```

---

### **Bagian 4: Alur Kerja Harian (Sederhana dan Konsisten)**

Setelah setup awal selesai, Anda bisa bekerja setiap hari dengan alur sebagai berikut:

1. **Masuk ke Devshell:**

   ```bash
   $ nix develop

   ```

2. **Nyalakan PostgreSQL:**

   ```bash
   (proyek-go) λ database:start &

   ```

3. **Jalankan Kode Go Anda:**

   ```bash
   (proyek-go) λ go run .

   ```

   Server akan aktif di `http://localhost:8080` dan langsung terhubung ke database karena `DATABASE_URL` telah terkonfigurasi otomatis.

4. **Koneksi Langsung ke Database (Jika Diperlukan):**

   Gunakan shortcut `db`:

   ```bash
   (proyek-go) λ db

   ```

5. **Matikan Database Setelah Selesai:**

   ```bash
   (proyek-go) λ database:stop

   ```

Selamat! Anda telah berhasil membangun fondasi proyek yang luar biasa kuat. Konfigurasi ini membagi tanggung jawab dengan jelas: `flake.nix` untuk tools, `devshell.toml` untuk layanan dan konfigurasi, dan `main.go` untuk logika aplikasi.

Tentu saja bisa\! Ini adalah permintaan dan pertanyaan yang sangat umum. Banyak developer (termasuk saya) lebih menyukai shell seperti Fish atau Zsh daripada Bash standar.

Anda benar sekali, `nix develop` (dan `nix-shell`) secara default akan membuka shell `bash`. Alasan utamanya adalah skrip-skrip internal yang digunakan Nix untuk mengatur environment (seperti mengatur `PATH`, variabel lingkungan, dll.) ditulis dalam sintaks `bash` untuk kompatibilitas maksimum.

Namun, ada beberapa cara elegan untuk tetap menggunakan Fish sebagai shell utama Anda di dalam environment Nix. Saya akan berikan dua solusi: **Cara Cepat & Manual** dan **Cara Otomatis & Paling Direkomendasikan**.

---

### Solusi 1: Cara Cepat & Manual (Modifikasi `flake.nix`)

Metode ini tidak memerlukan instalasi tool tambahan di sistem Anda. Kita akan memberitahu `flake.nix` untuk secara otomatis mengganti `bash` dengan `fish` setiap kali Anda masuk.

#### Langkah 1: Tambahkan `fish` ke `devshell.toml`

Pertama, `fish` harus menjadi bagian dari environment kita.
Buka `devshell.toml` dan tambahkan `fish` ke daftar paket.

```toml
# devshell.toml

[devshell]
packages = [
  "gopls",
  "fish" # <-- TAMBAHKAN INI
]

# ... sisa konfigurasi Anda ...
```

#### Langkah 2: Modifikasi `shellHook` di `flake.nix`

Kita akan menambahkan beberapa baris sihir ke `shellHook` di `flake.nix` Anda. Logika ini akan memeriksa: "Apakah saya sedang dalam shell interaktif, dan apakah shell ini BUKAN fish?". Jika ya, ia akan langsung menjalankan `exec fish`.

Buka `flake.nix` dan modifikasi bagian `shellHook`:

```nix
# flake.nix

# ...
        devShells.default = (pkgs.devshell.mkShell {
          imports = [ (pkgs.devshell.importTOML ./devshell.toml) ];
        }) // {
          shellHook = ''
            # Bagian lama kita untuk DATABASE_URL
            echo "=> [shellHook] Environment siap! Variabel DATABASE_URL telah di-set ke localhost:5432."
            export DATABASE_URL="postgres://korteks@localhost:5432/korteks?sslmode=disable"

            # ==========================================================
            # TAMBAHAN BARU UNTUK OTOMATIS MASUK KE FISH
            # ==========================================================
            # Cek jika kita berada di shell interaktif ($PS1 ada isinya)
            # DAN jika shell saat ini bukan fish ($FISH_VERSION kosong)
            if [ -n "$PS1" ] && [ -z "$FISH_VERSION" ]; then
              # Ganti proses bash saat ini dengan fish.
              # 'exec' penting agar tidak membuat sub-shell baru.
              echo "==> Bash terdeteksi, secara otomatis beralih ke Fish shell..."
              exec fish
            fi
          '';
        };
      # ...
```

**Bagaimana ini bekerja?**
`exec fish` akan menggantikan proses `bash` yang sedang berjalan dengan proses `fish` baru. Karena ini adalah penggantian (bukan pemanggilan sub-shell baru), `fish` akan **mewarisi semua environment variable** (`PATH`, `DATABASE_URL`, dll.) yang sudah disiapkan oleh Nix.

**Alur Kerja Anda Sekarang:**
Cukup jalankan `nix develop`. Anda akan masuk ke `bash` sesaat, melihat pesan `==> ...beralih ke Fish shell...`, dan prompt Anda akan langsung berubah menjadi prompt Fish, siap digunakan.

---

### Solusi 2: Cara Otomatis & Paling Direkomendasikan (`direnv`)

Ini adalah "standar emas" untuk pengalaman developer dengan Nix. Anda tidak perlu lagi mengetik `nix develop`. Cukup `cd` ke direktori proyek, dan environment akan aktif secara otomatis di dalam shell Fish Anda.

Metode ini memerlukan **setup satu kali** di sistem Anda, tetapi akan sangat sepadan.

#### Langkah 1: Instal `direnv` dan `nix-direnv` di Sistem Anda

Anda perlu menginstal dua program ini di sistem utama Anda (bukan hanya di dalam proyek). Jika Anda menggunakan NixOS atau Home Manager, ini cara termudah. Jika tidak, ikuti petunjuk instalasi di situs web mereka.

**Contoh dengan Home Manager:**

```nix
# Di home.nix Anda
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};
```

#### Langkah 2: "Hook" `direnv` ke Shell Fish Anda

Tambahkan baris berikut ke akhir file konfigurasi Fish Anda (`~/.config/fish/config.fish`). Ini hanya perlu dilakukan sekali seumur hidup.

```fish
# ~/.config/fish/config.fish

direnv hook fish | source
```

(Buka terminal baru setelah menyimpan file ini agar perubahan diterapkan).

#### Langkah 3: Konfigurasi Proyek

Template `devshell` sudah sangat baik karena ia sudah membuatkan file `.envrc` untuk kita. Kita hanya perlu mengisinya dengan satu baris.

1.  Buka file `.envrc` di direktori proyek Anda.
2.  Isi dengan baris berikut:
    ```bash
    # .envrc
    use flake
    ```

#### Langkah 4: Izinkan `direnv`

Untuk keamanan, `direnv` akan meminta izin saat pertama kali Anda masuk ke direktori.

1.  `cd` keluar dari direktori proyek, lalu masuk lagi.
    ```bash
    cd ..
    cd proyek-final/
    ```
2.  Anda akan melihat pesan dari `direnv`. Jalankan perintah yang disarankannya:
    ```bash
    direnv allow
    ```

**Selesai\! Keajaiban Terjadi.**

Sekarang, setiap kali Anda `cd proyek-final` menggunakan shell Fish normal Anda, `direnv` akan otomatis memuat seluruh environment Nix dari `flake.nix` Anda di latar belakang. Anda akan melihat semua _tools_ (`go`, `psql`) dan environment variable (`DATABASE_URL`) tersedia. Saat Anda `cd ..`, environment tersebut akan otomatis dibersihkan. **Anda tidak perlu lagi menjalankan `nix develop` sama sekali.**

### Rekomendasi

- **Solusi 1 (`shellHook`)** bagus jika Anda tidak ingin menginstal apa pun di sistem Anda dan tidak keberatan mengetik `nix develop`.
- **Solusi 2 (`direnv`)** adalah yang **paling saya rekomendasikan**. Meskipun butuh setup awal, pengalaman development sehari-hari menjadi jauh lebih mulus, cepat, dan transparan.

Ah, ini adalah masalah klasik yang sangat bagus\! Anda telah menemukan interaksi yang menarik antara empat komponen: Shell utama Anda (**Fish**), otomatisasi environment (**`direnv`**), editor teks Anda (**Neovim**), dan konfigurasi editor Anda (**NvChad**).

Penyebabnya hampir pasti adalah **konfigurasi NvChad itu sendiri**, yang secara eksplisit memberitahu terminal internalnya untuk menggunakan `bash` demi stabilitas dan konsistensi, tanpa mempedulikan shell default Anda.

Neovim memiliki pengaturan internal untuk menentukan program shell mana yang akan dijalankan saat Anda membuka terminal. NvChad, sebagai sebuah framework konfigurasi, mengatur default ini ke `bash`. Kabar baiknya, kita bisa dengan mudah mengubahnya.

### Solusi Langsung: Mengubah Pengaturan Shell di NvChad

Kita akan memberitahu NvChad untuk menggunakan `fish` sebagai shell untuk terminal internalnya.

1.  **Buka File Konfigurasi Kustom NvChad:**
    File utama untuk konfigurasi kustom NvChad biasanya ada di:
    `~/.config/nvim/lua/custom/chadrc.lua`

2.  **Tambahkan Pengaturan Shell:**
    Buka file tersebut. Anda akan melihat sebuah tabel Lua yang diawali dengan `local M = {}`. Di dalam tabel ini, tambahkan satu baris untuk mengatur `vim.o.shell`.

    **`~/.config/nvim/lua/custom/chadrc.lua`:**

    ```lua
    -- chadrc.lua

    ---@type ChadrcConfig
    local M = {}

    M.ui = {
      theme = 'onedark',
      -- contoh pengaturan lain...
    }

    -- ... pengaturan M lainnya ...

    -- ==========================================================
    -- TAMBAHKAN BARIS INI
    -- ==========================================================
    -- Menetapkan 'fish' sebagai shell untuk terminal internal (:term)
    vim.o.shell = "fish"
    -- ==========================================================

    return M
    ```

3.  **Simpan file dan restart Neovim.**

Sekarang, saat Anda membuka terminal di dalam Neovim (misalnya dengan `:term`), ia akan membuka shell `fish`.

#### **Alur Kerja yang Benar (Sangat Penting\!)**

Agar ini berfungsi dengan benar, Anda harus memastikan Neovim itu sendiri dijalankan dari dalam environment Nix.

1.  Buka terminal Fish normal Anda.
2.  `cd` ke direktori proyek Anda. `direnv` akan secara otomatis aktif dan memuat semua _tools_ dari `flake.nix` (termasuk `fish` versi Nix).
3.  Dari terminal yang **sudah diaktifkan oleh `direnv`** ini, jalankan `nvim`.
4.  Sekarang, di dalam `nvim`, buka terminal. Terminal baru ini akan menjadi `fish` dan juga akan memiliki akses ke semua _tools_ Nix Anda.

---

### Solusi Lanjutan: Integrasi `direnv` Langsung ke Neovim

Untuk pengalaman yang lebih mulus lagi, Anda bisa membuat Neovim "sadar" akan `direnv` secara langsung. Dengan cara ini, bahkan jika Anda membuka `nvim` dari luar direktori proyek, saat Anda membuka file di dalam proyek, environment-nya akan dimuat secara otomatis.

Ini dilakukan dengan menambahkan plugin `direnv` ke konfigurasi NvChad Anda.

1.  **Buka File Konfigurasi Plugin Kustom:**
    File untuk menambahkan plugin di NvChad adalah:
    `~/.config/nvim/lua/custom/plugins.lua`

2.  **Tambahkan Plugin `direnv.vim`:**
    Tambahkan blok kode untuk `direnv/direnv.vim` ke dalam daftar plugin Anda.

    **`~/.config/nvim/lua/custom/plugins.lua`:**

    ```lua
    local plugins = {
      -- Contoh plugin yang mungkin sudah ada
      {
        "nvim-treesitter/nvim-treesitter",
        opts = {
          ensure_installed = { "lua", "vim", "vimdoc" },
        },
      },

      -- ==========================================================
      -- TAMBAHKAN BLOK INI UNTUK INTEGRASI DIRENV
      -- ==========================================================
      {
        "direnv/direnv.vim",
        -- Tidak perlu event atau config khusus, plugin ini bekerja otomatis
      },
      -- ==========================================================
    }

    return plugins
    ```

3.  **Simpan file, restart `nvim`, dan jalankan `:Lazy sync`** untuk menginstal plugin baru tersebut.

**Apa Keuntungannya?**
Dengan plugin ini, Neovim akan secara aktif "berbicara" dengan `direnv`. Setiap kali Anda membuka buffer (file) dari proyek yang memiliki file `.envrc`, plugin ini akan secara otomatis memuat environment yang sesuai, termasuk semua variabel lingkungan dan `PATH` ke _tools_ Nix Anda. Ini membuat integrasi antara editor dan environment development Anda menjadi sempurna.

### Rekomendasi

1.  Lakukan **Solusi Langsung** terlebih dahulu (`vim.o.shell = "fish"`). Ini akan langsung menyelesaikan masalah utama Anda.
2.  Jika Anda menginginkan pengalaman yang paling mulus, pertimbangkan untuk menambahkan **Solusi Lanjutan** (plugin `direnv`).
