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
prompt = " (proyek-go) λ "
# Nonaktifkan pesan selamat datang default (opsional).
motd = ""

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
