export interface ExternalApiRequest {
  path: string;
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  body?: unknown;
  headers?: Record<string, string>;
}

export interface ExternalApiClient {
  request<TResponse>(request: ExternalApiRequest): Promise<TResponse>;
}

export type ExternalApiFailureReason =
  | 'TIMEOUT'
  | 'NETWORK_ERROR'
  | 'HTTP_ERROR'
  | 'INVALID_JSON';

export class ExternalApiClientError extends Error {
  constructor(
    public readonly reason: ExternalApiFailureReason,
    message: string,
    public readonly statusCode?: number,
    cause?: unknown,
  ) {
    super(message, { cause });
    this.name = 'ExternalApiClientError';
  }
}

export class FetchExternalApiClient implements ExternalApiClient {
  constructor(
    private readonly baseUrl: string | undefined,
    private readonly timeoutMs: number,
    private readonly fetchImplementation: typeof fetch = fetch,
  ) {}

  async request<TResponse>(request: ExternalApiRequest): Promise<TResponse> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.timeoutMs);

    try {
      const url = this.baseUrl
        ? new URL(request.path, this.baseUrl)
        : new URL(request.path);
      const response = await this.fetchImplementation(url, {
        method: request.method ?? 'GET',
        headers: {
          accept: 'application/json',
          ...(request.body === undefined
            ? {}
            : { 'content-type': 'application/json' }),
          ...request.headers,
        },
        body: request.body === undefined
          ? undefined
          : JSON.stringify(request.body),
        signal: controller.signal,
      });

      if (!response.ok) {
        throw new ExternalApiClientError(
          'HTTP_ERROR',
          `External API returned HTTP ${response.status}`,
          response.status,
        );
      }

      try {
        return await response.json() as TResponse;
      } catch (error) {
        throw new ExternalApiClientError(
          'INVALID_JSON',
          'External API returned invalid JSON',
          response.status,
          error,
        );
      }
    } catch (error) {
      if (error instanceof ExternalApiClientError) throw error;
      if (controller.signal.aborted) {
        throw new ExternalApiClientError(
          'TIMEOUT',
          'External API request timed out',
          undefined,
          error,
        );
      }
      throw new ExternalApiClientError(
        'NETWORK_ERROR',
        'External API request failed',
        undefined,
        error,
      );
    } finally {
      clearTimeout(timeout);
    }
  }
}
