FROM swift:5.1 as builder
WORKDIR /app
COPY . .
RUN swift build -c release

FROM swift:5.1-slim
WORKDIR /app
COPY --from=builder /app/.build/x86_64-unknown-linux/release/JWTSecurityLab .
COPY Resources /app/Resources
CMD ["./JWTSecurityLab"]
