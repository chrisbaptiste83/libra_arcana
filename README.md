# Libra Arcana

A digital library for occult and mystical ebooks. Browse, read, and build a personal reading list from a curated catalog of esoteric texts — all freely available online.

[![Ruby](https://img.shields.io/badge/Ruby-3.4-CC342D?logo=ruby&logoColor=white)](https://ruby-lang.org)
[![Rails](https://img.shields.io/badge/Rails-8.1-CC0000?logo=rubyonrails&logoColor=white)](https://rubyonrails.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql&logoColor=white)](https://postgresql.org)

## Features

- **Catalog** — Paginated ebook browser with full-text search, category filtering, and sort options
- **In-browser reader** — Read PDFs directly in the app via an embedded iframe viewer
- **Favorites** — Authenticated users can heart any book and view all favorites on their profile
- **Reading list** — Track books as *Want to Read*, *Currently Reading*, or *Completed* with live status updates via Turbo Streams
- **User profiles** — Personal dashboard showing stats, favorites, and the full reading list grouped by status
- **Admin panel** — Full CRUD for ebooks and categories, user management, and a statistics dashboard at `/admin`
- **AI descriptions** — A Rake task uses the Claude API to auto-generate descriptions from uploaded PDFs

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 8.1 |
| Language | Ruby 3.4 |
| Database | PostgreSQL 16 |
| Storage | AWS S3 (production), Local disk (development) |
| Frontend | Tailwind CSS, Stimulus.js, Turbo (Hotwire) |
| Auth | Devise 5.0 |
| Pagination | Pagy 43 |
| AI | Anthropic Claude API |
| Testing | RSpec 8, FactoryBot, Shoulda-Matchers, SimpleCov |
| Deployment | Kamal 2 |

## Getting Started

### Prerequisites

- Ruby 3.4.2 (use `rbenv` — see `.ruby-version`)
- Node.js 20+ and Yarn
- PostgreSQL 14+
- `poppler-utils` (for the AI description Rake task — `pdftoppm`)

```bash
# Arch Linux
sudo pacman -S poppler postgresql

# macOS
brew install poppler postgresql@16

# Ubuntu / Debian
sudo apt-get install poppler-utils postgresql
```

### Installation

```bash
git clone git@github.com:chrisbaptiste83/libra_arcana.git
cd libra_arcana

bundle install
yarn install

bin/rails db:create db:migrate
bin/rails db:seed
bin/rails server
```

Visit `http://localhost:3000`.

### Environment Variables

Copy `.env.example` to `.env` and fill in the values (`.env` is gitignored):

```bash
cp .env.example .env
```

| Variable | Required | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | Yes (for AI) | Anthropic Claude API key |
| `AWS_ACCESS_KEY_ID` | Production | AWS credentials for S3 storage |
| `AWS_SECRET_ACCESS_KEY` | Production | AWS secret |
| `AWS_REGION` | Production | S3 bucket region |
| `AWS_S3_BUCKET` | Production | S3 bucket name |
| `PGUSER` | No | PostgreSQL user (default: `chris`) |
| `PGPASSWORD` | No | PostgreSQL password |
| `PGHOST` | No | PostgreSQL host (default: `localhost`) |
| `DATABASE_URL` | Production | Full PostgreSQL connection URL |

## Running Tests

```bash
bundle exec rspec                        # full suite
bundle exec rspec spec/models            # model specs only
bundle exec rspec spec/requests          # request/controller specs only
bundle exec rspec --format documentation # verbose output
```

Coverage is reported by SimpleCov to `coverage/index.html` after each run.

## Admin Access

Create a user via `/users/sign_up`, then promote them in the Rails console:

```ruby
User.find_by(email: "you@example.com").update!(admin: true)
```

Admin routes are mounted at `/admin`.

## AI Description Generation

Requires `pdftoppm` (from `poppler-utils`) and a valid `ANTHROPIC_API_KEY`:

```bash
bin/rails ebooks:generate_descriptions
```

This renders the first three pages of each uploaded PDF and sends them to Claude to generate a contextual description.

## Deployment

Deployed via [Kamal 2](https://kamal-deploy.org) to `libra-arcana.online`. Review `config/deploy.yml` and set your secrets before deploying:

```bash
kamal setup    # first-time server provisioning
kamal deploy   # subsequent deploys
kamal logs     # tail production logs
```

## Project Structure

```
app/
  controllers/
    favorites_controller.rb           # POST/DELETE /favorites
    reading_list_items_controller.rb  # POST/PATCH/DELETE /reading_list_items
    profiles_controller.rb            # GET /profile
    ebooks_controller.rb
    categories_controller.rb
    admin/
  models/
    user.rb
    ebook.rb
    category.rb
    favorite.rb
    reading_list_item.rb
  views/
    profiles/
    shared/
      _favorite_button.html.erb
      _reading_list_button.html.erb
      _ebook_card.html.erb

spec/
  models/     # unit tests for all models
  requests/   # integration tests for all controllers
  factories/  # FactoryBot definitions
```

## License

This project is for personal and educational use. All ebook content is sourced from public domain or freely licensed archives.
