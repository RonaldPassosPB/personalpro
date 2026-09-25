using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.FileProviders;
using Microsoft.IdentityModel.Tokens;
using PersonalProAPI.Data;
using PersonalProAPI.Middlewares;
using PersonalProAPI.Services;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Escuta simultaneamente nas portas 5250 e 5255!
builder.WebHost.UseUrls("http://0.0.0.0:5250", "http://0.0.0.0:5255");

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
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Garante que as senhas dos usuários de demonstração ('admin123') estejam sincronizadas com BCrypt
var dbConn = app.Services.GetRequiredService<DbConnection>();
await DatabaseSeeder.GarantirHashesDemoAsync(dbConn);

// Middleware Global de Captura de Erros em Arquivo Diário
app.UseMiddleware<ErrorHandlingMiddleware>();

// Redirecionamento amigável caso digite /swagge
app.Use(async (ctx, next) =>
{
    if (ctx.Request.Path.Equals("/swagge", StringComparison.OrdinalIgnoreCase))
    {
        ctx.Response.Redirect("/swagger/index.html");
        return;
    }
    await next();
});

app.UseSwagger();
app.UseSwaggerUI();
app.UseCors("PersonalProCors");

// Serve o Painel/App Flutter Web compilado diretamente em http://localhost:5250 e http://localhost:5255
var flutterWebBuildDir = Path.GetFullPath(Path.Combine(app.Environment.ContentRootPath, "..", "personalpro_app", "build", "web"));
if (Directory.Exists(flutterWebBuildDir))
{
    var fileProvider = new PhysicalFileProvider(flutterWebBuildDir);
    app.UseDefaultFiles(new DefaultFilesOptions { FileProvider = fileProvider });
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = fileProvider,
        ServeUnknownFileTypes = true
    });
}

app.UseAuthentication();

// Middleware de Kill-Switch SaaS Multi-Tenant
app.UseMiddleware<TenantKillSwitchMiddleware>();

app.UseAuthorization();
app.MapControllers();

app.Run();
