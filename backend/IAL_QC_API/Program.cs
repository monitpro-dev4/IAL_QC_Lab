using IAL_QC_API;
using IAL_QC_API.Model;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.OpenApi;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    // "Authorize" button in Swagger: paste the token from api/Auth/Login
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        Description = "Sign in with api/Auth/Login, then paste the token here."
    });
    c.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document)] = new List<string>()
    });
});

// Login: every request must carry a valid token, except endpoints marked [AllowAnonymous]
builder.Services.AddAuthentication(LoginToken.Scheme)
    .AddScheme<AuthenticationSchemeOptions, TokenAuthenticationHandler>(LoginToken.Scheme, null);
builder.Services.AddAuthorization(o =>
    o.FallbackPolicy = new AuthorizationPolicyBuilder().RequireAuthenticatedUser().Build());

// Document file storage (folder, size limit, allowed types from appsettings "FileSettings")
builder.Services.AddSingleton<FileStorage>();
long maxUpload = (builder.Configuration.GetValue<long?>("FileSettings:MaxFileSizeMB") ?? 25) * 1024 * 1024 + 1024 * 1024;
builder.Services.Configure<FormOptions>(o => o.MultipartBodyLengthLimit = maxUpload);
builder.WebHost.ConfigureKestrel(o => o.Limits.MaxRequestBodySize = maxUpload);

// CORS: only the frontend URLs listed in appsettings "AllowedOrigins"
const string FrontendPolicy = "_frontendPolicy";
string[] allowedOrigins = builder.Configuration.GetSection("AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
builder.Services.AddCors(options =>
{
    options.AddPolicy(FrontendPolicy, policy =>
        policy.WithOrigins(allowedOrigins).AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

// Any unexpected error comes back as { "ErrorMessage": "..." } instead of an HTML error page.
// Full details go to the log; in Development the message is returned too.
app.UseExceptionHandler(errorApp => errorApp.Run(async context =>
{
    var ex = context.Features.Get<IExceptionHandlerFeature>()?.Error;
    app.Logger.LogError(ex, "Unhandled error on {Path}", context.Request.Path);
    context.Response.StatusCode = StatusCodes.Status500InternalServerError;
    await context.Response.WriteAsJsonAsync(new APIResponse
    {
        ErrorMessage = app.Environment.IsDevelopment() && ex != null ? ex.Message : "Something Went Wrong. Please Try Again."
    });
}));

app.UseSwagger();
app.UseSwaggerUI();

app.UseCors(FrontendPolicy);
app.UseAuthentication();

// A user with a temporary password (set by the admin) must change it before doing anything else
app.Use(async (context, next) =>
{
    bool mustChange = context.User.FindFirst(LoginToken.MustChangePasswordClaim)?.Value == "1";
    if (mustChange && !context.Request.Path.StartsWithSegments("/api/Auth"))
    {
        context.Response.StatusCode = StatusCodes.Status403Forbidden;
        await context.Response.WriteAsJsonAsync(new APIResponse { ErrorMessage = "Change Your Password To Continue" });
        return;
    }
    await next();
});

app.UseAuthorization();
app.MapControllers();

app.Run();
