import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

@Injectable()
export class RolesGuard implements CanActivate {
    constructor(private reflector: Reflector) { }

    canActivate(context: ExecutionContext): boolean {
        // @Roles can sit on the method or the whole controller (AdminController uses the class).
        // Reading only the handler let every signed-in user through the admin API.
        const roles = this.reflector.getAllAndOverride<string[]>('roles', [
            context.getHandler(),
            context.getClass(),
        ]);
        if (!roles) return true;
        const user = context.switchToHttp().getRequest().user;
        return !!user && roles.includes(user.role);
    }
}
