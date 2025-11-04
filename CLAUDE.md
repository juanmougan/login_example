# Project Context for Claude

This file provides context about the Rails authentication project for future AI assistance sessions.

## Project Overview

This is a Ruby on Rails application implementing authentication for both web and API access using **Rodauth** as the authentication framework.

### Key Technology Decisions

- **Framework**: Ruby on Rails 8.x
- **Database**: PostgreSQL 16 (running in Docker)
- **Authentication**: Rodauth with rodauth-rails gem
- **Password Hashing**: BCrypt
- **Styling**: Tailwind CSS
- **Database ORM**: Active Record (Sequel used only by Rodauth, configured to share AR connection)

### Why Rodauth?

After evaluating multiple authentication solutions (Devise, has_secure_password, Authentication Zero), we chose Rodauth because:

1. **API + Web Excellence**: Native support for both API (JWT/JSON) and web (session) authentication
2. **Complete Feature Set**: Built-in email verification, password reset, MFA, social login support
3. **Security First**: Maximum security by default with HMAC token protection
4. **Future-Proof**: Modular design allows adding features incrementally
5. **Best MFA Support**: When needed, supports TOTP, SMS codes, WebAuthn with complete UI

See `adrs.md` for the complete Architecture Decision Record with detailed comparison.

## Project Structure

### User Model

The application uses an `Account` model (Rodauth convention) with these fields:
- `name`: string (required)
- `email`: string (required, unique)
- `status_id`: integer (managed by Rodauth)
- Plus Rodauth-managed tables for password hashes, verification keys, etc.

**Note**: We call it "Account" in the code (Rodauth convention) but refer to it as "User" in discussion.

### Authentication Flow

**Web Authentication:**
- Session-based
- Routes prefixed with `/auth` (e.g., `/auth/login`, `/auth/create-account`)
- Redirects to `/dashboard` after login
- Dashboard shows "Hello, [name]" personalized welcome

**API Authentication:**
- JSON/session-based (JWT optional for future)
- Same `/auth` endpoints accept JSON requests
- API endpoints in `Api::V1` namespace
- User deletion available via API only

### Key Files

```
app/
├── models/
│   └── account.rb                    # User model with Rodauth integration
├── controllers/
│   ├── application_controller.rb     # Base controller with rodauth helpers
│   ├── dashboard_controller.rb       # Post-login welcome page
│   ├── rodauth_controller.rb         # Handles Rodauth views
│   └── api/
│       └── v1/
│           ├── base_controller.rb    # API base with authentication
│           └── users_controller.rb   # User endpoints (show, destroy)
├── misc/
│   └── rodauth_main.rb              # Main Rodauth configuration (IMPORTANT)
├── mailers/
│   └── rodauth_mailer.rb            # Authentication emails
└── views/
    ├── rodauth/                      # Authentication views (customizable)
    └── dashboard/
        └── index.html.erb            # Welcome page

config/
├── initializers/
│   ├── rodauth.rb                   # Rodauth initialization
│   └── sequel.rb                    # Sequel config (uses AR connection)
└── database.yml                     # PostgreSQL configuration

docker-compose.yml                    # PostgreSQL container
.env                                  # Environment variables (not in git)
```

## Important Conventions

### Use bin/ Commands

**Always use the bin/ stubs** instead of global commands:

```bash
# ✅ CORRECT - Use bin/ commands
bin/rails server
bin/rails console
bin/rails db:migrate
bin/rake routes
bin/bundle install

# ❌ INCORRECT - Don't use global commands
rails server
rails console
rake routes
bundle install
```

**Why?** The bin/ stubs ensure:
- Correct Ruby/Rails version
- Proper bundler setup
- Project-specific configurations
- Consistent behavior across environments

### Common Commands

```bash
# Server
bin/rails server           # or bin/rails s
bin/rails console          # or bin/rails c

# Database
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/rails db:reset

# Rodauth
bin/rails rodauth:routes   # View Rodauth routes
bin/rails generate rodauth:views
bin/rails generate rodauth:migration feature_name

# Docker
docker-compose up -d       # Start PostgreSQL
docker-compose down        # Stop PostgreSQL
docker-compose logs -f postgres  # View logs
```

## Configuration Files

### Database Configuration

PostgreSQL runs in Docker (see `docker-compose.yml`):
- Host: localhost
- Port: 5432
- User: postgres
- Password: postgres
- Database: myapp_development (and myapp_test)

Connection configured in `config/database.yml` using environment variables.

## Authentication Features

### Currently Implemented

✅ User registration with name and email
✅ Email verification flow
✅ Password reset functionality  
✅ Login/logout (web and API)
✅ Session-based authentication
✅ Personalized dashboard
✅ API endpoint for user deletion
✅ Tailwind CSS styled interface

### Future Enhancements (Documented but Not Implemented)

See `IMPLEMENTATION.md` section 10 for adding:
- Multi-factor authentication (TOTP, SMS, WebAuthn)
- Social login (Google, Facebook, GitHub)
- Role-based access control (with Pundit/CanCanCan)
- JWT support for stateless API
- Account lockout after failed attempts

## Key Rodauth Concepts

### Configuration

All Rodauth configuration is in `app/misc/rodauth_main.rb`:

```ruby
class RodauthMain < Rodauth::Rails::Auth
  configure do
    # Enable features
    enable :login, :logout, :create_account, :verify_account, :reset_password
    
    # Configure behavior
    login_redirect { "/dashboard" }
    
    # Add custom logic
    before_create_account do
      # Validate name field
    end
  end
end
```

### Features vs Modules

Rodauth uses "features" (not "modules"):
- Enable features: `enable :feature_name`
- Each feature provides routes, views, and logic
- Features are modular and independent

### Common Features

- `:login` - Basic login functionality
- `:logout` - Logout functionality
- `:create_account` - User registration
- `:verify_account` - Email verification
- `:reset_password` - Password reset flow
- `:change_password` - Change password when logged in
- `:change_login` - Change email address
- `:remember` - "Remember me" functionality
- `:otp` - TOTP-based 2FA
- `:recovery_codes` - Backup codes for 2FA
- `:webauthn` - Passkey/security key support
- `:omniauth` - Social login integration

### Helper Methods

Available in controllers and views:

```ruby
rodauth.logged_in?                    # Check if user is logged in
rodauth.require_authentication        # Redirect to login if not authenticated
current_account                       # Get current user (Account model)
rodauth.login_path                    # Path to login page
rodauth.create_account_path           # Path to registration page
rodauth.logout_path                   # Path to logout
```

## Development Workflow

### Starting Development

```bash
# 1. Start PostgreSQL
docker-compose up -d

# 2. Setup database (first time only)
bin/rails db:create
bin/rails db:migrate

# 3. Start Rails server
bin/rails s

# 4. Visit http://localhost:3000
```

### Making Changes

#### Adding a New Rodauth Feature

```bash
# 1. Check if feature needs migration
bin/rails generate rodauth:migration feature_name

# 2. Run migration
bin/rails db:migrate

# 3. Enable in app/misc/rodauth_main.rb
# Add to enable: list

# 4. Generate views if needed
bin/rails generate rodauth:views feature_name

# 5. Restart server
```

#### Modifying User Model

```bash
# 1. Generate migration
bin/rails generate migration AddFieldToAccounts field:type

# 2. Edit migration file

# 3. Run migration
bin/rails db:migrate

# 4. Update Account model validations/methods
# Edit app/models/account.rb

# 5. Restart server
```

#### Customizing Views

Views are in `app/views/rodauth/`:
- Edit directly (they're just ERB templates)
- Use Tailwind CSS classes
- Can regenerate: `bin/rails generate rodauth:views --force`

## Testing

### Manual Testing

**Web Flow:**
```bash
# 1. Visit http://localhost:3000
# 2. Click "Sign up"
# 3. Check email (letter_opener will open browser)
# 4. Verify account
# 5. Should redirect to /dashboard
```

**API Flow:**
```bash
# Create account
curl -X POST http://localhost:3000/auth/create-account \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","login":"[email protected]","password":"pass123","password-confirm":"pass123"}'

# Login
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{"login":"[email protected]","password":"pass123"}'

# Get user info
curl http://localhost:3000/api/v1/users/show -b cookies.txt
```

### Automated Testing

Not yet implemented. When adding tests:
- Use RSpec or Minitest
- Test authentication flows
- Test API endpoints
- Mock email sending
- Use database_cleaner

## Troubleshooting

### Common Issues

**"Can't connect to database"**
```bash
# Check PostgreSQL is running
docker-compose ps

# Check logs
docker-compose logs postgres

# Restart
docker-compose restart postgres
```

**"Undefined method 'rodauth'"**
```bash
# Restart Rails server
# Stop Spring if running
bin/spring stop
bin/rails s
```

**"Routes not found"**
```bash
# Rodauth routes don't show in bin/rails routes
# Use this instead:
bin/rails rodauth:routes
```

**"Email not sending"**
```bash
# Check letter_opener gem is installed
# Check config/environments/development.rb has:
# config.action_mailer.delivery_method = :letter_opener
```

## Documentation References

All detailed documentation is in the project root:

- **README.md** - Overview and quick start
- **adrs.md** - Architecture Decision Record (why Rodauth)
- **IMPLEMENTATION.md** - Complete step-by-step setup guide
- **DOCKER_SETUP.md** - PostgreSQL Docker guide
- **.env.example** - Environment variables template
- **.gitignore.additions** - Git ignore recommendations

### External Resources

- **Rodauth Documentation**: https://rodauth.jeremyevans.net/
- **Rodauth-Rails**: https://github.com/janko/rodauth-rails
- **Rails Guides**: https://guides.rubyonrails.org/
- **Tailwind CSS**: https://tailwindcss.com/docs

## Code Style and Patterns

### Ruby/Rails Conventions

- Follow standard Rails conventions
- Use `snake_case` for methods and variables
- Use `CamelCase` for classes
- Keep controllers thin, models focused
- Use concerns for shared behavior

### Rodauth Patterns

```ruby
# Configuration blocks
configure do
  enable :feature
  setting_name value
end

# Hooks (before/after)
before_action_name do
  # custom logic
end

after_action_name do
  # custom logic
end

# Overriding methods
method_name do
  # custom implementation
  super  # call original if needed
end
```

### API Response Format

```json
{
  "success": true,
  "data": { ... }
}

// or

{
  "error": "Error message",
  "field_errors": {
    "email": ["is invalid"]
  }
}
```

## Security Considerations

### Important Security Notes

1. **Never commit .env file** - Contains sensitive credentials
2. **HMAC Secret**: Uses Rails secret_key_base (secure by default)
3. **Password Reset Tokens**: Expire after configured time
4. **Email Verification**: Required before login (configurable)
5. **CSRF Protection**: Enabled for web, disabled for JSON requests
6. **SQL Injection**: Prevented by Sequel/Active Record
7. **Session Security**: HttpOnly cookies, secure in production

### Production Checklist

Before deploying to production:
- [ ] Change default database passwords
- [ ] Set strong HMAC secret
- [ ] Enable SSL/TLS
- [ ] Configure proper SMTP settings
- [ ] Set up database backups
- [ ] Enable rate limiting
- [ ] Review Rodauth security settings
- [ ] Set proper CORS headers for API
- [ ] Use environment variables for all secrets
- [ ] Enable logging and monitoring

## Git Workflow

### Branches

- `main` - Production-ready code
- `development` - Active development
- Feature branches: `feature/feature-name`

### Commit Messages

Follow conventional commits:
```
feat: add user registration
fix: resolve email verification bug
docs: update README with setup steps
refactor: simplify dashboard controller
test: add authentication flow tests
```

### Files to Never Commit

Already in `.gitignore`:
- `.env` and `.env.*` files
- `backup*.sql` files
- `/tmp/*`
- `/log/*`
- `/storage/*`
- Docker volumes

## Collaboration Notes

### When Working with This Project

1. **Read this file first** - Understand project context
2. **Check README.md** - Get overview and quick start
3. **Review adrs.md** - Understand architectural decisions
4. **Use bin/ commands** - Always prefer bin/ stubs
5. **Follow conventions** - Match existing code style
6. **Test changes** - Manually test authentication flows
7. **Update docs** - Keep documentation current

### When Making Changes

1. Create feature branch
2. Make changes
3. Test locally (web + API)
4. Update relevant documentation
5. Commit with clear message
6. Push and create PR (if applicable)

### Communication

When asking for help or reporting issues:
- Mention which authentication feature is involved
- Include error messages and stack traces
- Specify if issue is web or API
- Note which Rodauth features are enabled
- Include relevant code snippets

## Future Development

### Planned Features (Not Yet Implemented)

See `IMPLEMENTATION.md` section 10 for detailed guides on adding:

1. **JWT Support** - Stateless API authentication
2. **MFA/2FA** - Multi-factor authentication
3. **Social Login** - Google, Facebook, GitHub
4. **Roles & Permissions** - Admin, user roles with Pundit
5. **Account Recovery** - Security questions, backup emails
6. **Audit Logging** - Track authentication events
7. **Rate Limiting** - Prevent brute force attacks
8. **WebAuthn** - Passkey/security key support

### Technical Debt

Currently minimal. Future considerations:
- Add automated test suite (RSpec/Minitest)
- Set up CI/CD pipeline
- Add API documentation (OpenAPI/Swagger)
- Implement caching strategy
- Add background job processing (Sidekiq)
- Set up performance monitoring

## Tips for AI Assistants

### Context Awareness

- This is a Rails project with Rodauth authentication
- Use bin/ commands, not global commands
- Account model = User in conversation
- Authentication is in app/misc/rodauth_main.rb
- Sequel is only used by Rodauth (transparent to developer)

### When Helping with Code

- Suggest Rodauth features rather than custom code
- Keep authentication logic in rodauth_main.rb
- Use Rodauth hooks (before/after) for custom behavior
- Maintain separation: authentication (Rodauth) vs authorization (Pundit)
- Follow Rails conventions and existing patterns

### When Debugging

- Check Rodauth configuration first
- Verify enabled features match requirements
- Review Rodauth documentation for feature details
- Check database tables exist (migrations run?)
- Verify environment variables are set

### Common Requests

**"Add MFA"** → See IMPLEMENTATION.md section 10.2
**"Add social login"** → See IMPLEMENTATION.md section 10.3
**"Add roles"** → See IMPLEMENTATION.md section 10.5
**"Why Rodauth?"** → See adrs.md
**"Setup database"** → See DOCKER_SETUP.md
**"Customize views"** → Edit app/views/rodauth/

## Project Status

**Current Phase**: Initial Implementation Complete
- ✅ Basic authentication working
- ✅ Email verification functional
- ✅ Password reset functional
- ✅ API endpoints working
- ✅ Web interface styled with Tailwind

**Next Steps**: (When needed)
- Add automated tests
- Implement MFA
- Add social login
- Implement role-based access control
- Deploy to production

## Contact / Maintainer Notes

This file should be updated when:
- Major architectural decisions are made
- New features are added
- Development workflow changes
- Common issues are discovered
- New conventions are established

Keep this file as the single source of truth for project context.

---

**Last Updated**: Project initialization
**Rails Version**: 8.x
**Ruby Version**: 3.x
**Authentication**: Rodauth via rodauth-rails gem
