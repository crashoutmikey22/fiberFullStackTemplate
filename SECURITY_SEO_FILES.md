# Security and SEO Files Documentation

This document describes the security and SEO files that have been added to your Fiber application.

## Files Created

### 1. robots.txt (`/robots.txt`)
**Purpose**: Controls web crawler access to your site
**Features**:
- Blocks most LLMs and AI crawlers (GPTBot, Claude, PerplexityBot, etc.)
- Protects sensitive directories (/api/, /admin/, /private/, etc.)
- Allows public pages and health check endpoints
- Includes sitemap reference

**Blocked AI/LLM Bots**:
- GPTBot (OpenAI)
- Google-Extended (Google AI)
- ChatGPT-User
- Claude-Web, Claude-Bot, anthropic-ai (Anthropic)
- PerplexityBot
- YouBot (YouTube)
- And many others

### 2. security.txt (`/security.txt` and `/.well-known/security.txt`)
**Purpose**: Provides security researchers with contact information
**Features**:
- Standard format according to RFC 9116
- Contact information for security issues
- Encryption keys and policies
- Acknowledgments and hiring information
- Available at both `/security.txt` and `/.well-known/security.txt`

### 3. sitemap.xml (`/sitemap.xml`)
**Purpose**: Helps search engines discover and index your content
**Features**:
- XML sitemap format
- Includes main routes and API endpoints
- Last modified dates and change frequencies
- Priority settings for different pages

## Routes Added

The following routes have been added to `main.go`:

```go
// Security and SEO files from root
app.Get("/robots.txt", func(c *fiber.Ctx) error {
    return c.SendFile("./statics/robots.txt")
})

app.Get("/security.txt", func(c *fiber.Ctx) error {
    return c.SendFile("./statics/security.txt")
})

app.Get("/sitemap.xml", func(c *fiber.Ctx) error {
    return c.SendFile("./statics/sitemap.xml")
})

// Security.txt in .well-known directory (RFC 9116 standard)
app.Get("/.well-known/security.txt", func(c *fiber.Ctx) error {
    return c.SendFile("./statics/.well-known/security.txt")
})
```

## Configuration

### Update Domain
Remember to update the following in the files:
- Replace `yourdomain.com` with your actual domain
- Update email addresses in `security.txt`
- Modify sitemap URLs to match your domain

### Testing
You can test these files by visiting:
- `https://yourdomain.com/robots.txt`
- `https://yourdomain.com/security.txt`
- `https://yourdomain.com/.well-known/security.txt`
- `https://yourdomain.com/sitemap.xml`

## Security Considerations

1. **LLM Protection**: The robots.txt blocks most known AI crawlers, but determined actors may still ignore it
2. **Security.txt**: Make sure the email address is monitored and responsive
3. **Sitemap**: Only include public URLs that you want indexed by search engines

## Maintenance

- Update sitemap.xml as you add new public pages
- Review robots.txt periodically for new AI crawlers
- Keep security.txt contact information current
- Monitor security.txt for security reports

## Standards Compliance

- **robots.txt**: Follows Google and other search engine guidelines
- **security.txt**: Complies with RFC 9116
- **sitemap.xml**: Follows sitemap.org protocol