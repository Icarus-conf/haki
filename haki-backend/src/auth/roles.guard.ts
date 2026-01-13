import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable } from 'rxjs';

@Injectable()
export class RolesGuard implements CanActivate {
    constructor(private reflector: Reflector) { }

    canActivate(context: ExecutionContext): boolean | Promise<boolean> | Observable<boolean> {
        const roles = this.reflector.get<string[]>('roles', context.getHandler());
        if (!roles) {
            return true;
        }
        const request = context.switchToHttp().getRequest();
        const user = request.user;

        // Check if user object has role (it needs to be added to JWT payload or fetched)
        // For now assuming it's in the user object attached by JwtStrategy
        // Real implementation usually requires fetching user from DB if role is not in JWT
        // OR ensuring JWT payload has 'role'.

        // Optimally, we update AuthService to include 'role' in JWT.
        // For now, let's assume request.user has it if we update JWT strategy.

        return roles.includes(user.role);
    }
}
