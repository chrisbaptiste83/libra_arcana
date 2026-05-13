# Libra Arcana

Rails 8.1.2 app (newest Rails in the workspace). Ruby 3.4.2. SQLite3.

## Stack

- **Frontend**: Tailwind v4, esbuild (jsbundling-rails + cssbundling-rails), Hotwire
- **Auth**: Devise 5.0
- **Pagination**: Pagy 9.x
- **Storage**: AWS S3 (aws-sdk-s3), image_processing
- **AI**: Anthropic gem (Claude API)
- **Background jobs**: Solid Queue
- **Cache**: Solid Cache
- **Cable**: Solid Cable
- **Deploy**: Kamal + Thruster
- **Testing**: RSpec + Factory Bot + Faker + Shoulda Matchers + SimpleCov

## Dev Commands

```bash
bin/dev              # start server + esbuild + CSS watchers
bin/rails c
bin/rspec            # or: bundle exec rspec
bin/rails db:migrate
dbreset
rcheck
taildev
```

## Conventions

- **Tests: RSpec** — not Minitest. Use `describe`/`it`/`expect`. Factories in `spec/factories/`.
- Rubocop: `rubocop-rails-omakase`
- Shoulda Matchers for model validations/associations
- SimpleCov for coverage reports (output to `coverage/` — gitignored)
- Devise 5.0 API differs slightly from 4.x — check docs before touching auth

## Key Patterns

- **Newest Rails** in the workspace — use as the reference for modern conventions
- Pagy for pagination: `include Pagy::Backend` in controllers, `include Pagy::Frontend` in helpers
- Anthropic gem for AI features — check `app/services/` for AI integration
- S3 configured via ENV (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_BUCKET`, `AWS_REGION`)
- esbuild watch runs via `bin/dev` — JS entrypoint at `app/javascript/application.js`
