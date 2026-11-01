using MediatR;
using Yorungez.Application;

namespace Yorungez.Identity.Application;

public sealed record TokenPair(string AccessToken, DateTimeOffset AccessExpiresAt,
    string RefreshToken, DateTimeOffset RefreshExpiresAt);
public sealed record UserProfile(Guid Id, string Email, bool EmailConfirmed, string? FirstName, string? LastName);
public sealed record BrowserSession(Guid UserId, Guid FamilyId, string StampHash, DateTimeOffset ExpiresAt);
public sealed record BrowserLoginCommand(string Email, string Password) : ICommand<BrowserSession>;
public sealed record RegisterCommand(string Email, string Password, string Language, string? FirstName = null, string? LastName = null) : ICommand<ActionReceipt>;
public sealed record ConfirmEmailCommand(Guid UserId, string Token) : ICommand<ActionReceipt>;
public sealed record LoginCommand(string Email, string Password) : ICommand<TokenPair>;
public sealed record RefreshCommand(string RefreshToken) : ICommand<TokenPair>;
public sealed record LogoutCommand(Guid UserId, Guid FamilyId) : ICommand<ActionReceipt>;
public sealed record ResendConfirmationCommand(string Email, string Language) : ICommand<ActionReceipt>;
public sealed record ForgotPasswordCommand(string Email, string Language) : ICommand<ActionReceipt>;
public sealed record ResetPasswordCommand(Guid UserId, string Token, string Password) : ICommand<ActionReceipt>;
public sealed record SaveProfileCommand(Guid UserId, string? FirstName, string? LastName) : ICommand<UserProfile>;
public sealed record CurrentUserQuery(Guid UserId) : IQuery<UserProfile>;

public interface IIdentityGateway
{
    Task RegisterAsync(RegisterCommand command, CancellationToken ct);
    Task ConfirmEmailAsync(ConfirmEmailCommand command, CancellationToken ct);
    Task<TokenPair> LoginAsync(LoginCommand command, CancellationToken ct);
    Task<BrowserSession> LoginBrowserAsync(BrowserLoginCommand command, CancellationToken ct);
    Task<TokenPair> RefreshAsync(RefreshCommand command, CancellationToken ct);
    Task LogoutAsync(LogoutCommand command, CancellationToken ct);
    Task ResendConfirmationAsync(ResendConfirmationCommand command, CancellationToken ct);
    Task ForgotPasswordAsync(ForgotPasswordCommand command, CancellationToken ct);
    Task ResetPasswordAsync(ResetPasswordCommand command, CancellationToken ct);
    Task<UserProfile> SaveProfileAsync(SaveProfileCommand command, CancellationToken ct);
    Task<UserProfile> CurrentUserAsync(Guid userId, CancellationToken ct);
    Task<bool> ValidateSessionAsync(Guid userId, Guid familyId, string stampHash, CancellationToken ct);
}

public sealed record EmailMessage(string Recipient, string Subject, string Body, string? HtmlBody = null);
public interface IEmailDelivery { Task SendAsync(EmailMessage message, CancellationToken ct); }

public sealed class RegisterHandler(IIdentityGateway gateway) : IRequestHandler<RegisterCommand, ActionReceipt>
{
    public async Task<ActionReceipt> Handle(RegisterCommand request, CancellationToken ct)
    { Input.Email(request.Email); Input.Password(request.Password); Input.Name(request.FirstName); Input.Name(request.LastName); await gateway.RegisterAsync(request, ct); return new("Identity.RegistrationAccepted"); }
}
public sealed class ConfirmEmailHandler(IIdentityGateway gateway) : IRequestHandler<ConfirmEmailCommand, ActionReceipt>
{
    public async Task<ActionReceipt> Handle(ConfirmEmailCommand request, CancellationToken ct)
    { Input.Token(request.Token); await gateway.ConfirmEmailAsync(request, ct); return new("Identity.EmailConfirmed"); }
}
public sealed class LoginHandler(IIdentityGateway gateway) : IRequestHandler<LoginCommand, TokenPair>
{
    public Task<TokenPair> Handle(LoginCommand request, CancellationToken ct)
    { Input.Email(request.Email); Input.PasswordSize(request.Password); return gateway.LoginAsync(request, ct); }
}
public sealed class RefreshHandler(IIdentityGateway gateway) : IRequestHandler<RefreshCommand, TokenPair>
{
    public Task<TokenPair> Handle(RefreshCommand request, CancellationToken ct)
    { Input.Token(request.RefreshToken); return gateway.RefreshAsync(request, ct); }
}
public sealed class BrowserLoginHandler(IIdentityGateway gateway) : IRequestHandler<BrowserLoginCommand, BrowserSession>
{
    public Task<BrowserSession> Handle(BrowserLoginCommand request, CancellationToken ct)
    { Input.Email(request.Email); Input.PasswordSize(request.Password); return gateway.LoginBrowserAsync(request, ct); }
}
public sealed class LogoutHandler(IIdentityGateway gateway) : IRequestHandler<LogoutCommand, ActionReceipt>
{
    public async Task<ActionReceipt> Handle(LogoutCommand request, CancellationToken ct)
    { await gateway.LogoutAsync(request, ct); return new("Identity.LoggedOut"); }
}
public sealed class ResendHandler(IIdentityGateway gateway) : IRequestHandler<ResendConfirmationCommand, ActionReceipt>
{
    public async Task<ActionReceipt> Handle(ResendConfirmationCommand request, CancellationToken ct)
    { Input.Email(request.Email); await gateway.ResendConfirmationAsync(request, ct); return new("Identity.EmailRequestAccepted"); }
}
public sealed class ForgotPasswordHandler(IIdentityGateway gateway) : IRequestHandler<ForgotPasswordCommand, ActionReceipt>
{
    public async Task<ActionReceipt> Handle(ForgotPasswordCommand request, CancellationToken ct)
    { Input.Email(request.Email); await gateway.ForgotPasswordAsync(request, ct); return new("Identity.EmailRequestAccepted"); }
}
public sealed class ResetPasswordHandler(IIdentityGateway gateway) : IRequestHandler<ResetPasswordCommand, ActionReceipt>
{
    public async Task<ActionReceipt> Handle(ResetPasswordCommand request, CancellationToken ct)
    { Input.Token(request.Token); Input.Password(request.Password); await gateway.ResetPasswordAsync(request, ct); return new("Identity.PasswordReset"); }
}
public sealed class SaveProfileHandler(IIdentityGateway gateway) : IRequestHandler<SaveProfileCommand, UserProfile>
{
    public Task<UserProfile> Handle(SaveProfileCommand request, CancellationToken ct)
    { Input.Name(request.FirstName); Input.Name(request.LastName); return gateway.SaveProfileAsync(request, ct); }
}
public sealed class CurrentUserHandler(IIdentityGateway gateway) : IRequestHandler<CurrentUserQuery, UserProfile>
{
    public Task<UserProfile> Handle(CurrentUserQuery request, CancellationToken ct) => gateway.CurrentUserAsync(request.UserId, ct);
}

internal static class Input
{
    public static void Name(string? name)
    {
        if (string.IsNullOrWhiteSpace(name) || name.Trim().Length > 100 || name.Any(char.IsControl))
            throw new AppFailure("Identity.InvalidName", FailureKind.Validation);
    }
    public static void Email(string? email)
    {
        if (string.IsNullOrWhiteSpace(email) || email.Length > 254
            || !new System.ComponentModel.DataAnnotations.EmailAddressAttribute().IsValid(email))
            throw new AppFailure("Identity.InvalidEmail", FailureKind.Validation);
    }
    public static void Password(string? password)
    {
        if (password is null || password.Length is < 15 or > 128)
            throw new AppFailure("Identity.InvalidPassword", FailureKind.Validation);
    }
    public static void PasswordSize(string? password)
    {
        if (password is null || password.Length is < 1 or > 128)
            throw new AppFailure("Identity.InvalidCredentials", FailureKind.Unauthorized);
    }
    public static void Token(string? token)
    {
        if (string.IsNullOrWhiteSpace(token) || token.Length > 4096)
            throw new AppFailure("Identity.InvalidToken", FailureKind.Validation);
    }
}
