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
