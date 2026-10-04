using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.FileProviders;
using Microsoft.IdentityModel.Tokens;
using PersonalProAPI.Data;
using PersonalProAPI.Middlewares;
using PersonalProAPI.Services;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Se estiver rodando localmente (sem porta configurada pelo Azure/IIS), escuta nas portas 5250 e 5255
var isAzure = !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("WEBSITE_SITE_NAME")) ||
              !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("ASPNETCORE_PORT")) ||
              !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("HTTP_PLATFORM_PORT"));
if (!isAzure)
{
    builder.WebHost.UseUrls("http://0.0.0.0:5250", "http://0.0.0.0:5255");
}

// Serviços Singleton e Scoped (Padrão FightCenter)
builder.Services.AddSingleton<DbConnection>();
builder.Services.AddSingleton<LogService>();
builder.Services.AddSingleton<FcmService>();
builder.Services.AddScoped<NotificacaoService>();

// CORS liberado para Flutter Web e App Mobile
builder.Services.AddCors(options =>
{
    options.AddPolicy("PersonalProCors", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Autenticação JWT com Claims (usuarioId, perfil, personalId)
var jwtKey = builder.Configuration["Jwt:Key"]!;
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.DictionaryKeyPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    });
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHostedService<PagamentoBackgroundService>();

var app = builder.Build();

// Garante que as senhas dos usuários de demonstração ('admin123') estejam sincronizadas com BCrypt
try
{
    var dbConn = app.Services.GetRequiredService<DbConnection>();
    await DatabaseSeeder.GarantirHashesDemoAsync(dbConn);
}
catch (Exception ex)
{
    Console.WriteLine($"[AVISO BANCO DE DADOS NA INICIALIZAÇÃO] {ex.Message}");
}

// Middleware Global de Captura de Erros em Arquivo Diário
app.UseMiddleware<ErrorHandlingMiddleware>();

// Redirecionamento amigável para o Swagger e para a Landing Page Comercial de Planos
app.Use(async (ctx, next) =>
{
    var path = ctx.Request.Path.Value?.TrimEnd('/') ?? "";
    if (path.Equals("/planos", StringComparison.OrdinalIgnoreCase) ||
        path.Equals("/site", StringComparison.OrdinalIgnoreCase) ||
        path.Equals("/comercial", StringComparison.OrdinalIgnoreCase))
    {
        ctx.Response.Redirect("/site/index.html");
        return;
    }
    if (path.Equals("/swagge", StringComparison.OrdinalIgnoreCase))
    {
        ctx.Response.Redirect("/swagger/index.html");
        return;
    }
    await next();
});

app.UseSwagger();
app.UseSwaggerUI();
app.UseCors("PersonalProCors");

// Serve o Painel/App Flutter Web compilado (wwwroot em produção ou build/web em desenvolvimento)
var wwwrootDir = Path.Combine(app.Environment.ContentRootPath, "wwwroot");
var flutterWebBuildDir = Path.GetFullPath(Path.Combine(app.Environment.ContentRootPath, "..", "personalpro_app", "build", "web"));

if (Directory.Exists(wwwrootDir))
{
    app.UseDefaultFiles();
    app.UseStaticFiles(new StaticFileOptions
    {
        ServeUnknownFileTypes = true,
        OnPrepareResponse = ctx =>
        {
            ctx.Context.Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0";
            ctx.Context.Response.Headers["Pragma"] = "no-cache";
            ctx.Context.Response.Headers["Expires"] = "0";
        }
    });
}
else if (Directory.Exists(flutterWebBuildDir))
{
    var fileProvider = new PhysicalFileProvider(flutterWebBuildDir);
    app.UseDefaultFiles(new DefaultFilesOptions { FileProvider = fileProvider });
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = fileProvider,
        ServeUnknownFileTypes = true,
        OnPrepareResponse = ctx =>
        {
            ctx.Context.Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0";
            ctx.Context.Response.Headers["Pragma"] = "no-cache";
            ctx.Context.Response.Headers["Expires"] = "0";
        }
    });
}

app.UseAuthentication();

// Middleware de Kill-Switch SaaS Multi-Tenant
app.UseMiddleware<TenantKillSwitchMiddleware>();

app.UseAuthorization();
app.MapControllers();

app.Run();
