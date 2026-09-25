using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using PersonalProAPI.Data;
using PersonalProAPI.Middlewares;
using PersonalProAPI.Services;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

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

app.UseSwagger();
app.UseSwaggerUI();
app.UseCors("PersonalProCors");
app.UseAuthentication();

// Middleware de Kill-Switch SaaS Multi-Tenant
app.UseMiddleware<TenantKillSwitchMiddleware>();

app.UseAuthorization();
app.MapControllers();

app.Run();
