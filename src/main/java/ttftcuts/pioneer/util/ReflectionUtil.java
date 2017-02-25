package ttftcuts.pioneer.util;

import net.minecraftforge.fml.relauncher.ReflectionHelper;

import java.lang.reflect.Method;

public abstract class ReflectionUtil {

    public static <E> Method findMethod(E instance, String[] methodNames, Class<?>... methodTypes)
    {
        Exception failed = null;
        for (String methodName : methodNames)
        {
            try
            {
                Method m = instance.getClass().getMethod(methodName, methodTypes);
                //m.setAccessible(true);
                return m;
            }
            catch (Exception e)
            {
                failed = e;
            }
        }
        throw new ReflectionHelper.UnableToFindMethodException(methodNames, failed);
    }
}
