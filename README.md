# Libra Arcana

A digital library for occult and mystical ebooks. Browse, read, and build a personal reading list from a curated catalog of esoteric texts — all freely available online.

## Features

- **Catalog** — paginated ebook browser with full-text search, category filtering, and sort options
- **In-browser reader** — read PDFs directly in the app via an embedded iframe viewer
- **Favorites** — authenticated users can heart any book and view all favorites on their profile
- **Reading list** — track books as *Want to Read*, *Currently Reading*, or *Completed* with live status updates via Turbo Streams
- **User profiles** — personal dashboard showing stats, favorites, and the full reading list grouped by status
- **Admin panel** — full CRUD for ebooks and categories, user management, and a statistics dashboard
- **AI descriptions** — a Rake task uses the Claude API to auto-generate descriptions from uploaded PDFs

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 8.0 |
| Language | Ruby 3.4 |
| Database | SQLite3 (dev/test) |
| Storage | AWS S3 (production), Local disk (dev) |
| Frontend | Tailwind CSS, Stimulus.js, Turbo (Hotwire) |
| Auth | Devise |
| Pagination | Pagy |
| AI | Anthropic Claude API |
| Deployment | Kamal |
| Tests | RSpec, FactoryBot, Shoulda-Matchers, SimpleCov |

## Getting Started

### Prerequisites

- Ruby 3.4.2
- Node.js (for asset bundling)
- `poppler-utils` (for the AI description Rake task — `pdftoppm`)

### Installation

```bash
git clone https://github.com/your-username/libra_arcana.git
cd libra_arcana

bundle install
yarn install        # or: npm install

bin/rails db:create db:migrate
bin/rails server
```

Visit `http://localhost:3000`.

### Environment Variables

Copy `.env.example` to `.env` and fill in the values:

```
# AWS S3 (production only)
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=

# Anthropic Claude API (for ebook description generation)
ANTHROPIC_API_KEY=
```

### Seed Data

```bash
bin/rails db:seed
```

## Running Tests

```bash
bundle exec rspec                    # full suite
bundle exec rspec spec/models        # model specs only
bundle exec rspec spec/requests      # request/controller specs only
```

Coverage is reported by SimpleCov to `coverage/index.html` after each run.

## Admin Access

Create a user via `/users/sign_up`, then flip the `admin` flag in the Rails console:

```ruby
User.find_by(email: "you@example.com").update!(admin: true)
```

Admin routes are at `/admin`.

## AI Description Generation

Requires `pdftoppm` (part of `poppler-utils`) and a valid `ANTHROPIC_API_KEY`:

```bash
bin/rails ebooks:generate_descriptions
```

This renders the first three pages of each uploaded PDF and sends them to Claude to generate a description.

## Deployment

The app is configured for [Kamal](https://kamal-deploy.org) deployment. Review `config/deploy.yml` and set your secrets before deploying:

```bash
kamal deploy
```

## Project Structure

```
app/
  controllers/
    favorites_controller.rb          # POST/DELETE /favorites
    reading_list_items_controller.rb # POST/PATCH/DELETE /reading_list_items
    profiles_controller.rb           # GET /profile
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
  models/       # unit tests for all models
  requests/     # integration tests for all controllers
  factories/    # FactoryBot definitions
```

## License

This project is for personal and educational use. All ebook content is sourced from public domain or freely licensed archives.
