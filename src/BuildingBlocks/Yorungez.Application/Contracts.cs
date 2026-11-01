using MediatR;

namespace Yorungez.Application;

public interface ICommand<out TResponse> : IRequest<TResponse>;
public interface IQuery<out TResponse> : IRequest<TResponse>;

public enum FailureKind { Validation, Unauthorized, Forbidden, NotFound, Conflict, Unavailable }

public sealed class AppFailure(string code, FailureKind kind) : Exception(code)
{
    public string Code { get; } = code;
    public FailureKind Kind { get; } = kind;
}

public sealed record ActionReceipt(string Code);

public interface ITextCatalog
{
    string Get(string code, string culture);
}
